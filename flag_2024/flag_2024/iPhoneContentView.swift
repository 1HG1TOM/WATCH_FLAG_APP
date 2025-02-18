import SwiftUI
import WatchConnectivity

struct iPhoneContentView: View {
    @State private var fileName: String = ""  // ファイル名を保存するState変数
    @State private var showAlert = false      // 警告ダイアログを表示するためのState
    @State private var alertMessage = ""      // 警告メッセージを保存するためのState
    @State private var isFileManagerPresented = false  // ファイル管理ビューの表示を制御
    @ObservedObject var watchConnector = WatchConnectivityManager.shared  // WatchConnectivityManagerのインスタンスを参照
    
    var body: some View {
        NavigationView {
            VStack {
                // Apple Watchとの接続状況を表示
                if watchConnector.isReachable {
                    Text("Apple Watchと接続されています")
                        .foregroundColor(.green)
                } else {
                    Text("Apple Watchとの接続がありません")
                        .foregroundColor(.red)
                }
                
                // ファイル名を入力するTextField
                TextField("Enter file name", text: $fileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // ファイルを保存するボタン
                Button("Save to CSV") {
                    let success = watchConnector.saveTimestampsToCSV(fileName: fileName)  // WatchConnectivityManagerのメソッドを使用
                    
                    if !success {
                        // 同名ファイルが存在する場合、警告を表示
                        alertMessage = "同じファイル名が存在します。別の名前を入力してください。"
                        showAlert = true
                    } else {
                        // ファイル名とデータをリセット
                        fileName = ""  // テキストフィールドをクリア
                        watchConnector.timestamps.removeAll()  // 表示されているデータを消す
                    }
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Warning"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
                // 保存されたタイムスタンプのリストを表示
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading) {
                            if watchConnector.timestamps.isEmpty {
                                Text("ボタンがまだ押されていません")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                // タイムスタンプのリストを表示
                                ForEach(Array(watchConnector.timestamps.enumerated()), id: \.element) { index, entry in
                                    let components = entry.split(separator: ",")
                                    if components.count == 3 {
                                        HStack {
                                            Text("\(components[0])セット目")
                                                .font(.body)
                                            Divider()
                                            Text(components[1].trimmingCharacters(in: .whitespaces))
                                                .font(.body)
                                                .frame(minWidth: 80, alignment: .center)
                                            Divider()
                                            Text(components[2].trimmingCharacters(in: .whitespaces))
                                                .font(.body)
                                        }
                                        .padding(.vertical, 4)
                                        .id(index)  // 各行にIDを付ける
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(minHeight: 133, maxHeight: 133)  // ScrollViewの高さを設定
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2))  // ScrollView全体を囲む枠
                    .padding()
                    .onChange(of: watchConnector.timestamps) {
                        if let lastIndex = watchConnector.timestamps.indices.last {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
            .navigationBarItems(trailing: Button(action: {
                isFileManagerPresented = true  // ファイル管理ビューを表示
            }) {
                Text("ファイル管理")
            })
            .sheet(isPresented: $isFileManagerPresented) {
                FileManagerView()  // ファイル管理ビューを表示
            }
        }
        .onAppear {
            watchConnector.updateReachability()
        }
    }
}

struct iPhoneContentView_Previews: PreviewProvider {
    static var previews: some View {
        iPhoneContentView()
    }
}

