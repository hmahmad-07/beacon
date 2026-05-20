import 'dart:convert';

EmployesModel employesModelFromJson(String str) =>
    EmployesModel.fromJson(json.decode(str));

String employesModelToJson(EmployesModel data) => json.encode(data.toJson());

class EmployesModel {
  int? error;
  String? errorMsg;
  int? totalUsers;
  List<User>? users;

  EmployesModel({this.error, this.errorMsg, this.totalUsers, this.users});

  factory EmployesModel.fromJson(Map<String, dynamic> json) => EmployesModel(
    error: json["error"],
    errorMsg: json["error_msg"],
    totalUsers: json["total_users"],
    users: json["users"] == null
        ? null
        : List<User>.from(json["users"].map((x) => User.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "error": error,
    "error_msg": errorMsg,
    "total_users": totalUsers,
    "users": users == null
        ? null
        : List<dynamic>.from(users!.map((x) => x.toJson())),
  };
}

class User {
  String? userId;
  String? userName;
  String? empCode;
  String? department;
  String? designation;
  String? profilePic;

  User({
    this.userId,
    this.userName,
    this.empCode,
    this.department,
    this.designation,
    this.profilePic,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json["user_id"],
    userName: json["user_name"],
    empCode: json["emp_code"],
    department: json["department"],
    designation: json["designation"],
    profilePic: json["profile_pic"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "user_name": userName,
    "emp_code": empCode,
    "department": department,
    "designation": designation,
    "profile_pic": profilePic,
  };
}
