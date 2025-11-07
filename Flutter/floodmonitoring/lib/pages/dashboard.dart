import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../utils/style.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [

          //Header
          Container(
            color: Colors.red,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Greetings Vincent!!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  'Stay alert, stay safe',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          //Main

          Container(
            color: Colors.blue,
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      'Flood update\nto your zone',
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      decoration: BoxDecoration(
                        color: color2,
                        borderRadius: BorderRadius.all(
                          Radius.circular(5),
                        ),
                      ),
                      child:Text(
                        'Open Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      )
                    ), // This is a Button
                  ],
                ),

                //Image Part here
              ],
            ),
          ),


          // Related
          
          Container(
            color: Colors.pink,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Related',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ],
            )
          ),

          //Weather Card
          Container(
            color: Colors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                //Weather image

                Column(
                  children: [
                    Text(
                      'Weather',
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    Text('[Current Time]'),
                    Text('[Current Location]'),
                  ],
                ),
                
              ],
            ),
          ),


          //Sliding Cards

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                miniCard(
                  color: color2,
                  title: 'Recent\nAlert',
                  textColor: Colors.white,
                ),
                miniCard(
                  color: color1,
                  title: 'Flood\ntips',
                  textColor: Colors.black,
                ),
                miniCard(
                  color: color3,
                  title: 'Rescue\nCall',
                  textColor: Colors.black,
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget miniCard({
    required Color color,
    required String title,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      width: 130,
      height: 140,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                height: 1,
                fontSize: 20,
                fontWeight: FontWeight.w600
              ),
            ),
          ],
        )
    );
  }
}
