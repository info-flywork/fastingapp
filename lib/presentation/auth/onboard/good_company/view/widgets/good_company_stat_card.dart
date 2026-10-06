part of '../good_company_view.dart';

final class GoodCompanyStatCard extends StatelessWidget {
  const GoodCompanyStatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.iconPath,
    required this.iconTiltRadians,
    super.key,
  });

  final String value;
  final String label;
  final Color valueColor;
  final String iconPath;
  final double iconTiltRadians;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 2,
          color: ColorName.colorBlack.withValues(alpha: 0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTextStyles.goodCompanyStatValue.copyWith(
                        color: valueColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.goodCompanyStatLabel,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 0,
              child: Transform.rotate(
                angle: iconTiltRadians,
                child: Image.asset(
                  iconPath,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
