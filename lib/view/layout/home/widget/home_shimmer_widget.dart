import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';

class HomeShimmerWidget extends StatelessWidget {
  const HomeShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomShimmer(
        radius: 12,
        height: 200,
        width: double.infinity,
        shimmerColor: AppColor.mainAppColor(context),
        fillColor: AppColor.lightGreyColor(context),
      ),
    );
  }
}
