import 'package:centrex/core/models/employes_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'employee_detail_view.dart';

class EmployeeListView extends StatelessWidget {
  final String department;
  const EmployeeListView({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: CustomAppBar(title: department),
      body: Consumer<EmployesController>(
        builder: (context, controller, child) {
          final employees = controller.getEmployeesByDept(department);

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_rounded,
                    size: 15.w,
                    color: AppColor.grey,
                  ),
                  2.height,
                  Text(
                    "No members found",
                    style: TextStyle(fontSize: 4.5.sp, color: AppColor.grey),
                  ),
                ],
              ),
            );
          }

          return Builder(
            builder: (context) {
              return GridView.builder(
                padding: EdgeInsets.all(6.w),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4.w,
                  mainAxisSpacing: 4.w,
                  childAspectRatio: 0.72,
                ),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final user = employees[index];
                  return _buildEmployeeCard(context, user);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, User user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap:
            (user.department?.toLowerCase().contains("sales") == true ||
                user.department?.toLowerCase().contains("marketing") == true)
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailView(user: user),
                ),
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.all(2.w),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColor.appLightColor.withValues(alpha: 0.35),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: CachedNetworkImage(
                    imageUrl: user.profilePic ?? "",
                    fit: BoxFit.fill,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppColor.grey.withValues(alpha: 0.15),
                      highlightColor: AppColor.grey.withValues(alpha: 0.05),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: AppColor.appLightColor,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 18.h,
                        color: AppColor.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName ?? "N/A",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 3.8.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.appDarkColor,
                    ),
                  ),
                  0.6.height,
                  Row(
                    children: [
                      Icon(Icons.work, size: 3.w, color: AppColor.appColor2),
                      1.width,
                      Expanded(
                        child: Text(
                          user.designation ?? "N/A",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 3.sp,
                            color: AppColor.appDarkColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  .5.height,
                  Row(
                    children: [
                      Icon(Icons.badge, size: 3.w, color: AppColor.appColor2),
                      1.width,
                      Text(
                        "Emp Code: ",
                        style: TextStyle(
                          fontSize: 2.6.sp,
                          color: AppColor.grey,
                        ),
                      ),
                      Text(
                        user.empCode ?? "N/A",
                        style: TextStyle(
                          fontSize: 2.6.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.appColor1,
                        ),
                      ),
                    ],
                  ),
                  1.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
