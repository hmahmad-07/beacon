import 'package:beacon/core/constants/constants.dart';
import 'package:beacon/core/controllers/employes_controller.dart';
import 'package:beacon/core/extensions/routes.dart';
import 'package:beacon/core/extensions/sizer.dart';
import 'package:beacon/core/models/site_entry.dart';
import 'package:beacon/core/resources/app_colors.dart';
import 'package:beacon/ui/components/site_widgets.dart';
import 'package:beacon/ui/view/dashboard/site_home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final emp = context.read<EmployesController>();
      if (emp.shops.isEmpty && !emp.isLoading) {
        emp.getSites(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.scaffold,
        body: Consumer<EmployesController>(
          builder: (context, emp, _) {
            final sites = SiteEntry.fromShops(emp.shops);
            return Column(
              children: [
                const _Header(),
                Expanded(child: _body(context, emp, sites)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    EmployesController emp,
    List<SiteEntry> sites,
  ) {
    final notLoadedYet = emp.sitesDetailModel == null && !emp.sitesLoadFailed;
    if (notLoadedYet || (emp.isLoading && sites.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (sites.isEmpty) {
      return AppErrorView(
        icon: emp.sitesLoadFailed
            ? Icons.cloud_off_rounded
            : Icons.store_mall_directory_outlined,
        message: emp.sitesLoadFailed
            ? "Could not load your sites. Check your connection and try again."
            : "No sites are assigned to this account.",
        onRetry: () => emp.getSites(context),
      );
    }

    return RefreshIndicator(
      color: AppColor.appColor1,
      onRefresh: () => emp.getSites(context),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2.5.w,
          crossAxisSpacing: 2.5.w,
          childAspectRatio: 0.82,
        ),
        itemCount: sites.length,
        itemBuilder: (context, index) {
          final site = sites[index];
          return _SiteCard(
            site: site,
            onTap: () => AppRoutes.push(SiteHomeView(site: site)),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final name = Constants.name.trim();
    final greeting = name.isEmpty ? "Hello" : "Hello, $name";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.appLightColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColor.appDarkColor,
                  fontSize: 4.6.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              0.8.height,
              Text(
                "CENTREX",
                style: TextStyle(
                  color: AppColor.appColor1,
                  fontSize: 6.0.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              0.6.height,
              Text(
                "Your sites are listed below.",
                style: TextStyle(color: AppColor.grey, fontSize: 3.1.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.site, required this.onTap});

  final SiteEntry site;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = site.screenModules.length;

    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.appLightColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: SiteLogo(
                    asset: site.asset,
                    accent: site.accent,
                    size: 22.w,
                  ),
                ),
              ),
              1.height,
              Text(
                site.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 3.8.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.appDarkColor,
                ),
              ),
              0.4.height,
              Text(
                "$count ${count == 1 ? 'module' : 'modules'}",
                style: TextStyle(fontSize: 3.1.sp, color: AppColor.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
