import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

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

  //发送信息到另一端服务器
  Future<void> sendToPeer() async {
    isCanSend = false;
    socket.write(sendData);

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
        illumination = int.parse(receivedData.split(',')[0]);
        waterLevel = int.parse(receivedData.split(',')[1]);
        illuminationSafety = int.parse(receivedData.split(',')[2]);
        waterLevelSafety = int.parse(receivedData.split(',')[3]);
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
        title: const Text("基于tcp的控制器"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildInputField(),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: !isConnected ? tcpConnect : tcpCloseConnect,
              child: !isConnected ? const Text('建立连接') : const Text('断开连接')),
          const SizedBox(height: 40),
          _buildTextRow("光照：", Icons.sunny, Colors.orange, illumination, ' lux'),
          const SizedBox(height: 5),
          _buildTextRow("水位：", Icons.water_sharp, Colors.blueAccent, waterLevel, ' m'),
          const SizedBox(height: 20),
          Joystick(
            stick: const MyJoystickStick(),
            base: const JoystickBase(),
            listener: (move) {
              x = (move.x * 100).toInt();
              y = (move.y * 100).toInt();
              setState(() {
                sendData = "X: $x\nY: $y";
              });
              // print(sendData);
              if (isConnected) {
                sendToPeer();
              }
            },
            mode: JoystickMode.all,
          ),
          const SizedBox(height: 50),
          _buildSafeTextRow(illuminationSafety == 1 ? "明火安全" : "明火警告", illuminationSafety),
          const SizedBox(height: 5),
          _buildSafeTextRow(waterLevelSafety == 1 ? "水位安全" : "水位警告", waterLevelSafety),
        ],
      ),
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
      ElevatedButton(onPressed: isConnected && isCanSend ? sendToPeer : null, child: const Text("发送信息")),
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
