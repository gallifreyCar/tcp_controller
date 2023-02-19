//摇杆样式
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
