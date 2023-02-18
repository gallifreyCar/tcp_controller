import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //是否建立起连接
  bool isConnected = false;

  //是否可以发送信息
  bool isCanSend = true;

  //socket
  late Socket socket;

  //接收到的信息
  String receivedData = '无响应';
  static const defaultSendData = '你好，世界';

  //要发送的信息
  String sendData = defaultSendData;

  //主机地址和端口
  static const defaultHost = '192.168.0.251';
  static const defaultPort = 1234;

  String host = defaultHost;
  int port = defaultPort;

  //坐标
  int x = 0;
  int y = 0;

  //数据
  int waterLevel = 0;
  int illumination = 0;
  int waterLevelSafety = 1;
  int illuminationSafety = 1;
  int bulb = 0;
  //rangeSliver的默认值
  SfRangeValues _lightValues = const SfRangeValues(30.0, 60.0);
  SfRangeValues _waterValues = const SfRangeValues(60.0, 90.0);

  //发送信息到另一端服务器
  Future<void> sendToPeer(String data) async {
    isCanSend = false;
    socket.write(data);
    await socket.flush().onError((error, stackTrace) => {debugPrint(error.toString())});
    isCanSend = true;
  }

  //监听数据流
  Future<void> dataListener() async {
    socket.listen((event) {
      // print(event);
      String data = utf8.decode(event);

      setState(() {
        receivedData = data;
        if (receivedData != '无响应') {
          illumination = int.parse(receivedData.split(',')[0]);
          waterLevel = int.parse(receivedData.split(',')[1]);
          illuminationSafety = int.parse(receivedData.split(',')[2]);
          waterLevelSafety = int.parse(receivedData.split(',')[3]);
          bulb = int.parse(receivedData.split(',')[4]);
        }
      });
    });
  }

  //建立tcp链接
  void tcpConnect() async {
    socket = await Socket.connect(host, port);
    setState(() {
      isConnected = true;
    });
    dataListener();
  }

  //关闭tcp链接
  void tcpCloseConnect() async {
    await socket.close();
    setState(() {
      isConnected = false;
    });
  }

  //ui绘制
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("TCP控制器"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildInputField(),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: !isConnected ? tcpConnect : tcpCloseConnect,
              child: !isConnected ? const Text('建立连接') : const Text('断开连接')),

          _buildRougeSliver(const Icon(Icons.sunny, color: Colors.orange), 'light'),
          // const SizedBox(height: 5),
          _buildRougeSliver(const Icon(Icons.water_sharp, color: Colors.blueAccent), 'water'),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTextRow("光照：", Icons.sunny, Colors.orange, illumination, ' lux'),
              const SizedBox(width: 25),
              _buildTextRow("水位：", Icons.water_sharp, Colors.blueAccent, waterLevel, ' m'),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wb_incandescent,
                color: bulb == 1 ? Colors.red : Colors.black,
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: isConnected && isCanSend
                    ? () {
                        sendToPeer('F\r\n');
                      }
                    : null,
                label: const Text("灭火"),
                icon: const Icon(Icons.fire_extinguisher),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Joystick(
            stick: const MyJoystickStick(),
            base: const JoystickBase(),
            listener: (move) {
              x = (move.x * 100).toInt();
              y = (move.y * 100).toInt();
              setState(() {
                sendData = "X: $x,Y: $y\r\n";
              });
              // print(sendData);
              if (isConnected) {
                sendToPeer(sendData);
              }
            },
            mode: JoystickMode.all,
          ),
          const SizedBox(height: 10),
          _buildSafeTextRow(illuminationSafety == 1 ? "明火安全" : "明火警告", illuminationSafety),
          _buildSafeTextRow(waterLevelSafety == 1 ? "水位安全" : "水位警告", waterLevelSafety),
        ],
      ),
    );
  }

  //上下限设置ui
  Widget _buildRougeSliver(Icon icon, String tips) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        SizedBox(
          width: 300,
          child: SfRangeSlider(
            values: tips == 'light' ? _lightValues : _waterValues,
            min: 0,
            max: 150,
            interval: 30,
            showLabels: true,
            showTicks: true,
            enableTooltip: true,
            enableIntervalSelection: true,
            minorTicksPerInterval: 1,
            onChanged: (SfRangeValues value) {
              setState(() {
                tips == 'light' ? _lightValues = value : _waterValues = value;
              });
              if (isConnected) {
                tips == 'light'
                    ? sendToPeer('$tips:${_lightValues.start.toInt()},${_lightValues.end.toInt()}\r\n')
                    : sendToPeer('$tips:${_waterValues.start.toInt()},${_waterValues.end.toInt()}\r\n');
              }
            },
          ),
        ),
      ],
    );
  }

  //输入框ui
  Widget _buildInputField() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "主机地址",
              hintText: "例：192.168.0.251",
            ),
            onChanged: (e) => {
              setState(() {
                host = e;
              })
            },
          ),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "端口", hintText: "例：1234"),
            onChanged: (e) => {
              setState(() {
                port = int.parse(e);
              })
            },
          ),
        ],
      ),
    );
  }

  //收到的信息行ui
  Widget _buildTextRow(String text, IconData icon, Color color, int data, String unit) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(width: 5),
        Text(text, style: textStyle),
        Text(data.toString() + unit, style: textStyle),

        // Text(ascii.decode(utf8.decode(receivedData))),
      ],
    );
  }

  //收到安全警告ui
  Widget _buildSafeTextRow(String text, int safe) {
    final textStyle = TextStyle(color: safe == 1 ? Colors.green : Colors.redAccent, fontSize: 18);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          safe == 1 ? Icons.safety_check : Icons.warning,
          color: safe == 1 ? Colors.green : Colors.redAccent,
          size: 28,
        ),
        const SizedBox(width: 5),
        Text(text, style: textStyle),
        // Text(ascii.decode(utf8.decode(receivedData))),
      ],
    );
  }

  //测试用的自由发送信息模块（保留
  Widget _buildTestContent() {
    return Column(children: [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        width: 200,
        child: TextField(
          decoration: const InputDecoration(labelText: "要发送的信息"),
          onChanged: (e) => {
            setState(() {
              sendData = e;
            })
          },
        ),
      ),
      ElevatedButton(
          onPressed: isConnected && isCanSend
              ? () {
                  sendToPeer(sendData);
                }
              : null,
          child: const Text("发送信息")),
    ]);
  }
}

//摇杆样式
class MyJoystickStick extends StatelessWidget {
  const MyJoystickStick({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueAccent,
        boxShadow: [
          BoxShadow(color: Colors.blueGrey, offset: Offset(2.0, 2.0), blurRadius: 5.0),
        ],
      ),
      child: const Icon(
        Icons.gps_fixed_outlined,
        color: Colors.white70,
      ),
    );
  }
}
