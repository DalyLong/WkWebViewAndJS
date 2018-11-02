//
//  JSAndSwift.swift
//  WkWebViewAndJSDemo
//
//  Created by Public on 2018/9/30.
//  Copyright © 2018年 Long. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore

class JSAndSwift: UIViewController {

    var webView : WKWebView?
    var progressView : UIProgressView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        self.loadUrl()
    }
    
    private func initUI(){
        self.navigationItem.title = "加载网页"
        self.view.backgroundColor = UIColor.white
        
        let config = WKWebViewConfiguration()
        // 设置偏好设置
        config.preferences = WKPreferences()
        config.preferences.minimumFontSize = 10
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.processPool = WKProcessPool()
        config.userContentController = WKUserContentController()
        //注意在这里注入JS对象名称 "JSObject"
        config.userContentController.add(self, name: "JSObject")
        self.webView = WKWebView.init(frame: CGRect.init(x: 0, y: UIApplication.shared.statusBarFrame.height+44, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height-UIApplication.shared.statusBarFrame.height-44), configuration: config)
        
        //禁止3DTouch
        self.webView?.allowsLinkPreview = false
        self.webView?.navigationDelegate = self
        //添加监听
        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        //这行代码可以是侧滑返回webView的上一级，而不是根控制器（*只针对侧滑有效）
        self.webView?.allowsBackForwardNavigationGestures = true
        self.view.addSubview(self.webView!)
        
        self.progressView = UIProgressView.init(progressViewStyle: .default)
        self.progressView?.frame = CGRect.init(x: 0, y: UIApplication.shared.statusBarFrame.height+44, width: UIScreen.main.bounds.width, height: 5)
        self.progressView?.trackTintColor = UIColor.init(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        self.progressView?.progressTintColor = UIColor.green
        self.progressView?.isHidden = true
        self.view.addSubview(self.progressView!)
        
        self.addRightItem()
    }
    
    func addRightItem() {
        let button = UIButton.init(type: .custom)
        button.isUserInteractionEnabled = true
        button.setTitleColor(UIColor.init(red: 54/255, green: 147/255, blue: 249/255, alpha: 1), for: .normal)
        button.setTitleColor(UIColor.init(red: 100/255, green: 174/255, blue: 235/255, alpha: 1), for: .highlighted)
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.titleLabel?.textAlignment = .right
        button.frame = CGRect.init(x: 0, y: 0, width: 70, height: 44)
        button.addTarget(self, action: #selector(righItemAction), for: .touchUpInside)
        button.setTitle("调用js", for: .normal)
        
        let negativeSpacer = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -10
        let backItem = UIBarButtonItem.init(customView: button)
        self.navigationItem.rightBarButtonItems = [negativeSpacer,backItem]
    }
    
    @objc func righItemAction(){
        //调用js的addList方法
        self.webView?.evaluateJavaScript("addList()", completionHandler: { (any, error) in
            if (error != nil) {
                print(error.debugDescription)
            }
        })
    }
    
    private func loadUrl(){
        let url = URL.init(fileURLWithPath:Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "vue")!)
        let request = URLRequest.init(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 15.0)
        self.webView?.load(request)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            self.progressView?.alpha = 1
            self.progressView?.setProgress(Float((self.webView?.estimatedProgress)!), animated: true)
            if (self.webView?.estimatedProgress)! >= Double(1) {
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                    self.progressView?.alpha = 0
                }, completion: { (finished) in
                    self.progressView?.setProgress(0, animated: false)
                })
            }
        }else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //这个方法防止内存泄漏，写在合适的位置即可
        self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "JSObject")
    }
    
    deinit {
        self.webView?.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension JSAndSwift : WKNavigationDelegate{
    ///页面开始加载
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.progressView?.isHidden = false
    }
    ///开始获取到网页内容时返回
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    ///页面加载完成之后调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.progressView?.isHidden = true
    }
    ///页面加载失败时调用
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
}

extension JSAndSwift : WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        //接收js传过来的内容
        //name:js对象的名字（这里为JSObject）
        //message:js传过来的信息
        let alert = UIAlertController.init(title: message.name, message: message.body as? String, preferredStyle: .alert)
        let sure = UIAlertAction.init(title: "确定", style: .default) { (_) in}
        let canel = UIAlertAction.init(title: "取消", style: .cancel) { (_) in}
        alert.addAction(canel)
        alert.addAction(sure)
        self.present(alert, animated: true, completion: nil)
    }
}
