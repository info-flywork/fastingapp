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
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: ColorName.colorWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İkon transparan; metin altına sızabilir. Negatif
                      // letterSpacing son glifi (örn. +) kesmesin diye sağ pay.
                      Padding(
                        padding: const EdgeInsets.only(right: 44),
                        child: Text(
                          value,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
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
                    child: appImage(
                      iconPath,
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Border üstte kalsın; ikonlar kenarı örtmesin.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  width: 2,
                  color: ColorName.colorBlack.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
