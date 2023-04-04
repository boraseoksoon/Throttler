//
//  ContentView.swift
//  Throttler
//
//  Created by Seoksoon Jang on 2021/04/10.
//

import SwiftUI
import Throttler

struct ContentView: View {
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                if #available(iOS 16.0, *) {
                    (0...100000).forEach { i in
                        throttle(.seconds(0.01)) {
                            print(i)
                        }
                    }
                } else {
                    (0...100000).forEach { i in
                        throttle(seconds: 0.01) {
                            print(i)
                        }
                    }
                }
                
    //            0
    //            18133
    //            36058
    //            57501
    //            82851
                
            }) {
                Text("throttle")
            }
            
            Button(action: {
                if #available(iOS 16.0, *) {
                    debounce {
                        print("fired after 1 second")
                    }
                } else {
                    debounce(seconds: 1.0, on: .main) {
                        print("fired after 1 second")
                    }
                }
                
                // (click a button as fast as you can)
                // ....
                // ....
                // ....
                // fired after 1 second

            }) {
                Text("""
                     debounce
                     (click a button continuously as fast as you can)
                     """)
            }
            
            Button(action: {
                if #available(iOS 16.0, *) {
                    delay(.seconds(2)) {
                        print("fired after 2 sec")
                    }
                    
//                    delay {
//                        print("fired after 1 sec")
//                    }
                    
                } else {
                    delay(seconds: 2) {
                        print("fired after 2 sec")
                    }
                }

                // (delay 2 second..)
                // ...
                // fired after 2 sec

            }) {
                Text("delay")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
