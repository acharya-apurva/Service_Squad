import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_squad/view/book_service_address_view.dart';

class BookServiceView extends StatefulWidget {
  final service;

  const BookServiceView({super.key, required this.service});

  @override
  State<BookServiceView> createState() => _BookServiceViewState();
}

class _BookServiceViewState extends State<BookServiceView> {
  late Widget _currentWidget;
  int? startTime;
  int? endTime;
  TextEditingController _startTimeController = TextEditingController();
  TextEditingController _endTimeController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  Widget? _bottomNavBar;

  @override
  void initState() {
    super.initState();
    _currentWidget = selectDateWidget();
  }

  @override
  Widget build(BuildContext context) {
    if (startTime != null) {
      int minutes = startTime! % 2 * 30;
      String strMinutes = "";
      if (minutes < 10) {
        strMinutes = "0$minutes";
      } else {
        strMinutes = "$minutes";
      }
      _startTimeController.text = "${(startTime! / 2).floor()}:$strMinutes";
    } else {
      _startTimeController.text = "";
    }

    if (endTime != null) {
      int minutes = endTime! % 2 * 30;
      String strMinutes = "";
      if (minutes < 10) {
        strMinutes = "0$minutes";
      } else {
        strMinutes = "$minutes";
      }
      _endTimeController.text = "${(endTime! / 2).floor()}:$strMinutes";
    } else {
      _endTimeController.text = "";
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white), // Set the color here
        backgroundColor: Colors.deepPurple,
        title: Center(
          child: Text("Book Service",
              style: GoogleFonts.lilitaOne(
                color: Colors.white,
                fontSize: 48,
              )),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12.0),
              child: _currentWidget,
            ),
          ),
          if (_bottomNavBar != null) _bottomNavBar!,
        ],
      ),
    );
  }

  Widget selectDateWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select a date:"),
        CalendarDatePicker(
            initialDate: selectedDate,
            currentDate: selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.utc(
              DateTime.now().year + 1,
              DateTime.now().month,
              DateTime.now().day,
            ),
            onDateChanged: (DateTime date) {
              selectedDate = date;
              print(date);
            }),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentWidget = selectTimeWidget();
                _bottomNavBar = timeNavBar();
              });
            },
            label: const Text("Next"),
            icon: Icon(Icons.chevron_right),
          ),
        )
      ],
    );
  }

  Widget timeNavBar() {
    return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
          // color: Colors.deepPurpleAccent,
          color: Colors.white,
        ),

        // color: Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Start time:",
                ),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextField(
                      controller: _startTimeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        enabled: false,
                        // hintText: 'Enter a search term',
                      ),
                    ),
                  ),
                ),
                const Text("End time:"),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextField(
                      controller: _endTimeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        enabled: false,
                        // hintText: 'Enter a search term',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        startTime = null;
                        endTime = null;
                      });
                    },
                    label: const Text("Clear selected"),
                    icon: Icon(Icons.clear),
                  ),
                ),
              ],
            ),
            Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentWidget = selectDateWidget();
                        _bottomNavBar = null;
                      });
                    },
                    label: const Text("Go back"),
                    icon: Icon(Icons.chevron_left),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (startTime != null && endTime != null) {
                        DateTime bookingStart = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            (startTime! / 2).floor(),
                            startTime! % 2);
                        DateTime bookingEnd = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            (endTime! / 2).floor(),
                            endTime! % 2);
                        // Go to next screen to get address.
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BookServiceAddressView(
                                      service: widget.service,
                                      bookingStart: bookingStart,
                                      bookingLength: endTime! - startTime!,
                                    )));
                      } else {
                        const snackBar = SnackBar(
                          content: Text('Please select an available time.'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    label: const Text("Next"),
                    icon: Icon(Icons.chevron_right),
                  ),
                ),
              ],
            ))
          ],
        ));
  }

  Widget selectTimeWidget() {
    List<Widget> columnChildren = [];
    columnChildren.add(const Text("Select a time:"));
    columnChildren.addAll(getTimes());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnChildren,
    );
  }

  List<Widget> getTimes() {
    List<Widget> result = [];

    for (int i = 0; i < 24; i++) {
      result.add(ElevatedButton(
        style: ButtonStyle(
            fixedSize: MaterialStateProperty.all<Size>(Size(100, 20))),
        onPressed: () {
          selectTime(i * 2);
        },
        child: Text("$i:00"),
      ));
      result.add(ElevatedButton(
        style: ButtonStyle(
            fixedSize: MaterialStateProperty.all<Size>(Size(100, 20))),
        onPressed: () {
          selectTime((i * 2) + 1);
        },
        child: Text("$i:30"),
      ));
    }

    return [
      Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: result,
        ),
      ),
    ];
  }

  void selectTime(int time) {
    setState(() {
      if (startTime == null) {
        startTime = time;
      } else {
        if (time > startTime!) {
          endTime = time;
        }
      }
    });
  }
}
