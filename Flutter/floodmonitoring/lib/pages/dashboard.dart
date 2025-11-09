import 'package:floodmonitoring/services/weather.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  final double latitude = 14.6255;
  final double longitude = 121.1245;

  String temperature = '';
  String description = '';
  String iconCode = '';

  String currentTime = DateFormat('hh:mm a').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    getWeather();
  }


  void getWeather() async {
    final weather = await loadWeather(latitude, longitude);

    if (weather != null) {
      setState(() {
        temperature = weather['temperature'].toString();
        description = weather['description'];
        iconCode = weather['iconCode'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [

          SizedBox(height: 30),

          ///Header
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
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

          SizedBox(height: 15),


          ///Main

          Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: color1,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  child: Container(
                    height: 140,
                    width: 180,
                    decoration: BoxDecoration(
                      color: color1_2,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(300),
                        topRight: Radius.circular(40),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      //padding: EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Flood update\nto your zone',
                            style: const TextStyle(
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(height: 10),

                          GestureDetector(
                            onTap: (){
                              Navigator.pushNamed(context, '/map');
                            },
                            child: Container(
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
                            ),
                          ), // This is a Button
                        ],
                      ),
                    ),

                    Image.asset(
                      'assets/images/Flood-amico.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ],
            ),
          ),


          SizedBox(height: 15),


          /// Related

          
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Related',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600
                  ),
                ),

              ],
            )
          ),

          SizedBox(height: 15),

          ///Weather Card
          Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: color3_2,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    if (iconCode != '')
                      Image.asset(
                        'assets/images/weather/$iconCode.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),

                  ],
                ),


                Column(
                  children: [
                    Text(
                      currentTime,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600
                      ),
                    ),

                    Text(
                      '${temperature}°C',
                      style: TextStyle(
                        color: color1_2,
                        fontSize: 30,
                        fontWeight: FontWeight.w700
                      ),
                    ),

                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600
                      ),
                    ),

                  ],
                ),
                
              ],
            ),
          ),

          SizedBox(height: 15),


          ///Sliding Cards

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  miniCard(
                    color: color2,
                    title: 'Recent\nAlert',
                    textColor: Colors.white,
                    image: 'assets/images/warning.png',
                    opacity: 0.1,
                  ),
                  miniCard(
                    color: color1,
                    title: 'Flood\ntips',
                    textColor: Colors.black,
                    image: 'assets/images/water-damage.png',
                    opacity: 0.3,
                  ),
                  miniCard(
                    color: color3,
                    title: 'Rescue\nCall',
                    textColor: Colors.black,
                    image: 'assets/images/siren-on.png',
                    opacity: 0.5,
                  ),
                ],
              ),
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

    required String image,
    required double opacity,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: 120,
      height: 130,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  image,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),


            Positioned(
              left: 15,
              bottom: 15  ,
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  height: 1,
                  fontSize: 20,
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
          ],
        )
    );
  }
}
