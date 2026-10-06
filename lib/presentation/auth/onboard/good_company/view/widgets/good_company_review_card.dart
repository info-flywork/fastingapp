part of '../good_company_view.dart';

final class GoodCompanyReviewCard extends StatelessWidget {
  const GoodCompanyReviewCard({
    required this.name,
    required this.quote,
    required this.avatarPath,
    super.key,
  });

  final String name;
  final String quote;
  final String avatarPath;

  static const _avatarSize = 58.0;

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorName.colorWhite,
                      border: Border.all(
                        width: 2,
                        color: ColorName.colorBlack.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Transform.translate(
                          offset: const Offset(20, 6),
                          child: Transform.scale(
                            scale: 1.85,
                            alignment: const Alignment(0.5, -0.4),
                            child: Image.asset(avatarPath, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.goodCompanyReviewer),
                      const SizedBox(height: 2),
                      const _StarRow(
                        size: 20,
                        gap: 0,
                        alignment: MainAxisAlignment.start,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(quote, style: AppTextStyles.goodCompanyQuote),
          ],
        ),
      ),
    );
  }
}
