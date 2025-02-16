import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:nat_explorer/api/CommonDeviceApi.dart';
import 'package:nat_explorer/constants/Constants.dart';
import 'package:nat_explorer/pb/service.pb.dart';
import 'package:nat_explorer/pb/service.pbgrpc.dart';
import 'package:grpc/grpc.dart';

class UdpPortListPage extends StatefulWidget {
  UdpPortListPage({Key key, this.device}) : super(key: key);

  Device device;

  @override
  _UdpPortListPageState createState() => _UdpPortListPageState();
}

class _UdpPortListPageState extends State<UdpPortListPage> {
  static const double IMAGE_ICON_WIDTH = 30.0;
  List<PortConfig> _ServiceList = [];

  @override
  void initState() {
    super.initState();
    refreshmUDPList();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _ServiceList.map(
      (pair) {
        var listItemContent = Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 15.0),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                child: Icon(Icons.devices),
              ),
              Expanded(
                  child: Text(
                "${pair.description}(${pair.remotePort})",
                style: Constants.titleTextStyle,
              )),
              Constants.rightArrowIcon
            ],
          ),
        );
        return InkWell(
          onTap: () {
            //打开此端口的详情
            _pushDetail(pair);
          },
          child: listItemContent,
        );
      },
    );
    final divided = ListTile.divideTiles(
      context: context,
      tiles: tiles,
    ).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text("UDP端口列表"),
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () {
                //刷新端口列表
                refreshmUDPList();
              }),
          IconButton(
              icon: Icon(
                Icons.add_circle,
                color: Colors.white,
              ),
              onPressed: () {
//                TODO 添加UDP端口
                _addUDP(widget.device).then((v) {
                  refreshmUDPList();
                });
              }),
        ],
      ),
      body: ListView(children: divided),
    );
  }

  void _pushDetail(PortConfig config) async {
    final List _result = [];
    _result.add("端口:${config.remotePort}");
    _result.add("映射到端口:${config.localProt}");
    _result.add("描述:${config.description}");
    _result.add("转发连接状态:${config.remotePortStatus ? "在线" : "离线"}");
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final tiles = _result.map(
            (pair) {
              return ListTile(
                title: Text(
                  pair,
                  style: Constants.titleTextStyle,
                ),
              );
            },
          );
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(title: Text('端口详情'), actions: <Widget>[
              IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    //TODO 删除
                    _deleteCurrentUDP(config);
                  }),
//                IconButton(
//                  icon: Icon(
//                    Icons.open_in_browser,
//                    color: Colors.white,
//                  ),
//                  onPressed: () {
//    //                TODO 使用某种方式打开此端口
//                    _launchURL("http://127.0.0.1:${config.localProt}");
//                  }),
            ]),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  Future refreshmUDPList() async {
    try {
      CommonDeviceApi.getAllUDP(widget.device).then((v) {
        setState(() {
          _ServiceList = v.portConfigs;
        });
      });
    } catch (e) {
      print('Caught error: $e');
    }
  }

  Future _addUDP(Device device) async {
    TextEditingController _description_controller =
        TextEditingController.fromValue(TextEditingValue(text: "我的UDP"));
    TextEditingController _remote_port_controller =
        TextEditingController.fromValue(TextEditingValue(text: ""));
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: Text("添加端口："),
                content: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _description_controller,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                        labelText: '备注',
                        helperText: '自定义备注',
                      ),
                    ),
                    TextFormField(
                      controller: _remote_port_controller,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                        labelText: '端口号',
                        helperText: '该机器的端口号',
                      ),
                    )
                  ],
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text("取消"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text("添加"),
                    onPressed: () {
                      var UDPConfig = PortConfig();
                      UDPConfig.device = device;
                      UDPConfig.description = _description_controller.text;
                      UDPConfig.remotePort =
                          int.parse(_remote_port_controller.text);
                      CommonDeviceApi.createOneUDP(UDPConfig).then((restlt) {
                        Navigator.of(context).pop();
                      });
                    },
                  )
                ]));
  }

  Future _deleteCurrentUDP(PortConfig config) async {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
                title: new Text("删除UDP"),
                content: new Text("确认删除此UDP？"),
                actions: <Widget>[
                  new FlatButton(
                    child: new Text("取消"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  new FlatButton(
                    child: new Text("删除"),
                    onPressed: () {
                      CommonDeviceApi.deleteOneUDP(config).then((result) {
                        Navigator.of(context).pop();
                      });
                    },
                  )
                ])).then((v) {
      Navigator.of(context).pop();
    }).then((v) {
      refreshmUDPList();
    });
  }

  _launchURL(String url) async {
    AndroidIntent intent = AndroidIntent(
      action: 'action_view',
      data: url,
    );
    await intent.launch();
  }
}
