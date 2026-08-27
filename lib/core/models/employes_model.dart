import 'dart:convert';

SitesDetailModel sitesDetailModelFromJson(String str) =>
    SitesDetailModel.fromJson(json.decode(str));

String sitesDetailModelToJson(SitesDetailModel data) =>
    json.encode(data.toJson());

class SitesDetailModel {
  int? error;
  String? errorMsg;
  int? totalShops;
  List<Shop>? shops;

  SitesDetailModel({this.error, this.errorMsg, this.totalShops, this.shops});

  factory SitesDetailModel.fromJson(Map<String, dynamic> json) =>
      SitesDetailModel(
        error: json["error"],
        errorMsg: json["error_msg"] ?? json["message"],
        totalShops: json["total_shops"],
        shops: json["shops"] == null
            ? null
            : List<Shop>.from(json["shops"].map((x) => Shop.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "error": error,
    "error_msg": errorMsg,
    "total_shops": totalShops,
    "shops": shops == null
        ? null
        : List<dynamic>.from(shops!.map((x) => x.toJson())),
  };
}

class Shop {
  String? shopId;
  String? shopName;
  List<Department>? departments;

  Shop({this.shopId, this.shopName, this.departments});

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
    shopId: json["shop_id"],
    shopName: json["shop_name"],
    departments: json["departments"] == null
        ? null
        : List<Department>.from(
            json["departments"].map((x) => Department.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "shop_id": shopId,
    "shop_name": shopName,
    "departments": departments == null
        ? null
        : List<dynamic>.from(departments!.map((x) => x.toJson())),
  };
}

class Department {
  int? departmentId;
  String? departmentName;
  int? employeeCount;

  Department({this.departmentId, this.departmentName, this.employeeCount});

  factory Department.fromJson(Map<String, dynamic> json) => Department(
    departmentId: json["department_id"],
    departmentName: json["department_name"],
    employeeCount: json["employee_count"],
  );

  Map<String, dynamic> toJson() => {
    "department_id": departmentId,
    "department_name": departmentName,
    "employee_count": employeeCount,
  };
}
// ==========================================================================================================================
// ==========================================================================================================================
// ==========================================================================================================================
// ==========================================================================================================================

class EmployesModel {
  int? error;
  String? errorMsg;
  int? totalUsers;
  List<User>? users;

  EmployesModel({this.error, this.errorMsg, this.totalUsers, this.users});

  factory EmployesModel.fromJson(Map<String, dynamic> json) => EmployesModel(
    error: json["error"],
    errorMsg: json["error_msg"] ?? json["message"],
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
  dynamic id;
  String? userId;
  String? userName;
  String? empCode;
  String? department;
  String? designation;
  String? profilePic;
  String? gender;
  String? mobile;
  String? shopId;
  String? shopName;
  String? status;

  User({
    this.id,
    this.userId,
    this.userName,
    this.empCode,
    this.department,
    this.designation,
    this.profilePic,
    this.gender,
    this.mobile,
    this.shopId,
    this.shopName,
    this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json["id"];
    final empCode = json["emp_code"] ?? json["employee_code"]?.toString();
    final rawUserId =
        json["user_id"]?.toString() ??
        (rawId != null && rawId != 0 && rawId.toString() != "0"
            ? rawId.toString()
            : empCode);
    return User(
      id: rawId,
      userId: rawUserId,
      userName: json["user_name"] ?? json["name"],
      empCode: empCode,
      department: json["department"] ?? json["department_name"],
      designation: json["designation"],
      profilePic: json["profile_pic"],
      gender: json["gender"],
      mobile: json["mobile"],
      shopId: json["shop_id"]?.toString(),
      shopName: json["shop_name"],
      status: json["status"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "user_name": userName,
    "emp_code": empCode,
    "department": department,
    "designation": designation,
    "profile_pic": profilePic,
    "gender": gender,
    "mobile": mobile,
    "shop_id": shopId,
    "shop_name": shopName,
    "status": status,
  };
}

class DepartmentEmployeesModel {
  int? error;
  String? errorMsg;
  int? totalEmployees;
  dynamic departmentId;
  String? departmentName;
  List<EmployeeItem>? employees;

  DepartmentEmployeesModel({
    this.error,
    this.errorMsg,
    this.totalEmployees,
    this.departmentId,
    this.departmentName,
    this.employees,
  });

  factory DepartmentEmployeesModel.fromJson(Map<String, dynamic> json) =>
      DepartmentEmployeesModel(
        error: json["error"],
        errorMsg: json["error_msg"] ?? json["message"],
        totalEmployees: json["total_employees"],
        departmentId: json["department_id"],
        departmentName: json["department_name"],
        employees: json["employees"] == null
            ? null
            : List<EmployeeItem>.from(
                json["employees"].map((x) => EmployeeItem.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
    "error": error,
    "error_msg": errorMsg,
    "total_employees": totalEmployees,
    "department_id": departmentId,
    "department_name": departmentName,
    "employees": employees == null
        ? null
        : List<dynamic>.from(employees!.map((x) => x.toJson())),
  };
}

class EmployeeItem {
  dynamic id;
  String? employeeCode;
  String? name;
  String? designation;
  String? gender;
  String? mobile;
  String? shopId;
  String? shopName;
  dynamic departmentId;
  String? status;
  String? profilePic;

  EmployeeItem({
    this.id,
    this.employeeCode,
    this.name,
    this.designation,
    this.gender,
    this.mobile,
    this.shopId,
    this.shopName,
    this.departmentId,
    this.status,
    this.profilePic,
  });

  factory EmployeeItem.fromJson(Map<String, dynamic> json) => EmployeeItem(
    id: json["id"],
    employeeCode: json["employee_code"]?.toString(),
    name: json["name"],
    designation: json["designation"],
    gender: json["gender"],
    mobile: json["mobile"],
    shopId: json["shop_id"]?.toString(),
    shopName: json["shop_name"],
    departmentId: json["department_id"],
    status: json["status"],
    profilePic: json["profile_pic"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "employee_code": employeeCode,
    "name": name,
    "designation": designation,
    "gender": gender,
    "mobile": mobile,
    "shop_id": shopId,
    "shop_name": shopName,
    "department_id": departmentId,
    "status": status,
    "profile_pic": profilePic,
  };

  User toUser([String? parentDepartmentName]) {
    final String? resolvedUserId =
        (id != null && id != 0 && id.toString() != "0")
        ? id.toString()
        : employeeCode;
    return User(
      id: id,
      userId: resolvedUserId,
      userName: name,
      empCode: employeeCode,
      department:
          parentDepartmentName ??
          (departmentId != null ? "Dept $departmentId" : null),
      designation: designation,
      profilePic: profilePic,
      gender: gender,
      mobile: mobile,
      shopId: shopId,
      shopName: shopName,
      status: status,
    );
  }
}
