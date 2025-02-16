import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:nat_explorer/constants/Config.dart';

import 'fileExplorer/services/connection.dart';
import 'fileExplorer/services/connection_methods.dart';

class SSHWebPage extends StatefulWidget {
  SSHWebPage(
      {Key key,
      this.runId,
      this.remoteIp,
      this.remotePort,
      this.userName,
      this.passWord,
      this.localPort})
      : super(key: key);
  String runId;
  String remoteIp;
  int remotePort;
  String userName;
  String passWord;
  int localPort;

  @override
  State<StatefulWidget> createState() => SSHWebPageState();
}

class SSHWebPageState extends State<SSHWebPage> {
  // 标记是否是加载中
  bool loaded = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  // WebView加载状态变化监听器
  StreamSubscription<WebViewStateChanged> _onStateChanged;

  // 插件提供的对象，该对象用于WebView的各种操作
  FlutterWebviewPlugin flutterWebViewPlugin = FlutterWebviewPlugin();

  @override
  void initState() {
    super.initState();
    // 监听WebView的加载事件，该监听器已不起作用，不回调
    _onStateChanged =
        flutterWebViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      // state.type是一个枚举类型，取值有：WebViewState.shouldStart, WebViewState.startLoad, WebViewState.finishLoad
      switch (state.type) {
        case WebViewState.shouldStart:
          // 准备加载
          break;
        case WebViewState.startLoad:
          // 开始加载
          injectConfig();
          break;
        case WebViewState.finishLoad:
          // 加载完成
          break;
        case WebViewState.abortLoad:
          break;
      }
    });
  }

  // 解析WebView中的数据
  Future injectConfig() async {
    if (loaded) {
      return;
    }
    loaded = true;
    print("loaded = true");
    print("===");
    String jsCode =
        "window.localStorage.setItem(\'runId\', \'${widget.runId}\');window.localStorage.setItem(\'remoteIp\', \'${widget.remoteIp}\');window.localStorage.setItem(\'remotePort\', \'${widget.remotePort}\');window.localStorage.setItem(\'userName\', \'${widget.userName}\');window.localStorage.setItem(\'passWord\', \'${widget.passWord}\');location.reload();";
    flutterWebViewPlugin.evalJavascript(jsCode).then((result) {
      // result json字符串，包含token信息
      print("===");
      print(result);
      print("===");
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      appBar: AppBar(
        title: Text("ssh"),
        iconTheme: IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.insert_drive_file,
                color: Colors.white,
              ),
              onPressed: () {
                _pushSSHFileExplorer();
              }),
        ],
      ),
      key: _scaffoldKey,
      url:
          "http://${Config.webgRpcIp}:${Config.webStaticPort}/web/open/ssh/index.html",
      // 登录的URL
      withZoom: true,
      // 允许网页缩放
      withLocalStorage: true,
      // 允许LocalStorage
      withJavascript: true, // 允许执行js代码
    );
  }

  @override
  void dispose() {
    // 回收相关资源
    _onStateChanged.cancel();
    flutterWebViewPlugin.dispose();

    super.dispose();
  }

  void _pushSSHFileExplorer() async {
    // 查看设备下的服务 CommonDeviceServiceTypesList
//    Navigator.of(context).push(
//      MaterialPageRoute(
//        builder: (context) {
//          // 写成独立的组件，支持刷新
//          return Text('文件浏览器');
//        },
//      ),
//    );

    Connection _connection = Connection();
    _connection.address = "${Config.webgRpcIp}";
    _connection.port = '${widget.localPort}';
    _connection.username = widget.userName;
    _connection.passwordOrKey = widget.passWord;
    ConnectionMethods.connectClient(
      context,
      address: _connection.address,
      port: int.parse(_connection.port),
      username: _connection.username,
      passwordOrKey: _connection.passwordOrKey,
    ).then((bool connected) {
//      Navigator.popUntil(context, ModalRoute.withName("/"));
      Navigator.of(context).pop();
      if (connected) {
        ConnectionMethods.connect(context, _connection);
      } else {
        print('fail');
      }
    });
  }
}
