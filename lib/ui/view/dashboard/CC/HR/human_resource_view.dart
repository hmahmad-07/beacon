import 'package:beacon/ui/components/custom_appbar.dart';
import 'package:flutter/material.dart';

class CCHumanResourceView extends StatefulWidget {
  final String siteName;
  final String siteID;
  final String deptName;
  final int deptID;
  const CCHumanResourceView({
    super.key,
    required this.siteName,
    required this.siteID,
    required this.deptName,
    required this.deptID,
  });

  @override
  State<CCHumanResourceView> createState() => _CCHumanResourceViewState();
}

class _CCHumanResourceViewState extends State<CCHumanResourceView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.deptName),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Site Name: ${widget.siteName}"),
              Text("Site ID: ${widget.siteID}"),
              Text("Department Name: ${widget.deptName}"),
              Text("Department ID: ${widget.deptID}"),
            ],
          ),
        ),
      ),
    );
  }
}
