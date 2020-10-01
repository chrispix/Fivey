//
//  ContentView.swift
//  Shared
//
//  Created by Joel Bernstein on 8/30/20.
//

import SwiftUI
import WebView

struct ContentView: View {
    @ObservedObject var webViewStore = WebViewStore()

    var body: some View {
        NavigationView {
            WebView(webView: webViewStore.webView)
                .navigationBarTitle(Text(verbatim: webViewStore.webView.title ?? ""), displayMode: .inline)
        }.onAppear {
            self.webViewStore.webView.load(URLRequest(url: URL(string: "https://www.purpleair.com/map?opt=1/i/mAQI/a10/cC0#11/37.973/-122.1015")!))
        }.onOpenURL { url in
            self.webViewStore.webView.load(URLRequest(url: url))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
