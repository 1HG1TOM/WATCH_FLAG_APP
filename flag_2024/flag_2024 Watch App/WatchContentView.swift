//
//  WatchContentView.swift
//  flag_2024 Watch App
//
//  Created by 萩原亜依 on 2024/09/04.
//

import SwiftUI

struct WatchContentView: View {
    @ObservedObject var watchConnector = WatchConnectivityManager.shared
    
    // タブの選択を管理するState変数
    @State private var selectedTab = 0         // 最初は1ページ目（タブ0）
    @State private var isStartEnabled = true   // 最初はセット開始だけ有効
    @State private var isFlagEnabled = false   // フラグは最初は無効
    @State private var isEndEnabled = false    // セット終了は最初は無効
    
    // ボタンが押されたときのアニメーション用State
    @State private var isPressedStart = false
    @State private var isPressedEnd = false
    @State private var isPressedFlag = false
    
    // タブの遷移をトラックするための変数
    @State private var previousTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {  // タブの選択をStateで管理
            // 1ページ目：セット開始とセット終了
            VStack {
                // セット開始ボタン
                Button("セット開始") {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressedStart = true
                    }
                    startSet()
                    WKInterfaceDevice.current().play(.click)  // ハプティックフィードバックを追加
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            isPressedStart = false
                        }
                    }
                    // セット開始後に2ページ目に移動
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        selectedTab = 1  // 2ページ目に移動
                    }
                }
                .padding()
                .frame(width: isPressedStart ? 140 : 150, height: isPressedStart ? 45 : 50)  // 押した時に小さくする
                .background(isStartEnabled ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(45)
                .disabled(!isStartEnabled)
                .buttonStyle(PlainButtonStyle())  // デフォルトのボタンスタイルを無効にする

                // セット終了ボタン
                Button("セット終了") {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressedEnd = true
                    }
                    endSet()
                    WKInterfaceDevice.current().play(.click)  // ハプティックフィードバックを追加
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            isPressedEnd = false
                        }
                    }
                }
                .padding()
                .frame(width: isPressedEnd ? 140 : 150, height: isPressedEnd ? 45 : 50)  // 押した時に小さくする
                .background(isEndEnabled ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(45)
                .disabled(!isEndEnabled)
                .buttonStyle(PlainButtonStyle())
            }
            .tabItem {
                Text("セット管理")
            }
            .tag(0)  // 1ページ目のタブにタグ0を設定

            // 2ページ目：フラグボタン
            VStack {
                ZStack {
                    Circle()
                        .fill(isFlagEnabled ? Color.green : Color.gray)
                        .frame(width: isPressedFlag ? WKInterfaceDevice.current().screenBounds.width * 0.75 : WKInterfaceDevice.current().screenBounds.width * 0.8,
                               height: isPressedFlag ? WKInterfaceDevice.current().screenBounds.width * 0.75 : WKInterfaceDevice.current().screenBounds.width * 0.8)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isPressedFlag = true
                            }
                            if isFlagEnabled {
                                sendEvent(eventName: "フラグ")
                                WKInterfaceDevice.current().play(.click)  // ハプティックフィードバックを追加
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    isPressedFlag = false
                                }
                            }
                        }

                    Text("フラグ")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            .tabItem {
                Text("フラグ")
            }
            .tag(1)  // 2ページ目のタブにタグ1を設定
        }
        .tabViewStyle(PageTabViewStyle()) // スワイプでページを切り替えるスタイル
        .onChange(of: selectedTab) { newTab in
            if previousTab == 1 && newTab == 0 {  // 2ページ目から1ページ目に戻った場合
                WKInterfaceDevice.current().play(.notification)  // バイブレーションを追加
            }
            previousTab = newTab  // 遷移後のタブを保存
        }
    }

    // セット開始時の処理
    func startSet() {
        DispatchQueue.main.async {
            sendEvent(eventName: "セット開始")
            isStartEnabled = false
            isFlagEnabled = true
            isEndEnabled = true
        }
    }

    // セット終了時の処理
    func endSet() {
        DispatchQueue.main.async {
            sendEvent(eventName: "セット終了")
            isStartEnabled = true
            isFlagEnabled = false
            isEndEnabled = false
        }
    }

    // イベント名とタイムスタンプを送信する関数
    func sendEvent(eventName: String) {
        let timestamp = Date().timeIntervalSince1970
        DispatchQueue.main.async {
            WatchConnectivityManager.shared.sendTimestampWithEvent(eventName: eventName, timestamp: timestamp)
        }
    }
}


struct WatchContentView_Previews: PreviewProvider {
    static var previews: some View {
        WatchContentView()
    }
}
