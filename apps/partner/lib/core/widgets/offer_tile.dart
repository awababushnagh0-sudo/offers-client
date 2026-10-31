import 'package:kernel/kernel.dart';
import 'package:stellar/stellar.dart';

import '../../features/offers/domain/offer.dart';
import '../l10n/generated/partner_localizations.dart';

/// The offer as a row on home, to find the one to open: photo with the
/// discount, title, price, and how much of a limited offer is left, in
/// big figures. The Offers tab shows more (`OfferCard`).
class OfferTile extends StatelessWidget {
  const OfferTile({required this.offer, this.onTap, super.key});

  final Offer offer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = PartnerLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return SDealTile(
      imageUrl: offer.thumbUrl,
      title: offer.title,
      price: formatPrice(offer.offerPrice, languageCode: language),
      discountPercent: offer.discountPercent,
      stock: _stock(s, offer),
      onTap: onTap,
    );
  }
}

/// How much is left; null for unlimited offers.
DealTileStock? _stock(PartnerLocalizations s, Offer offer) {
  final total = offer.totalQuantity;
  if (total == null) return null;
  final left = offer.remainingQuantity ?? 0;
  return DealTileStock(
    left: left,
    total: total,
    note: s.ofTotal(total),
    label: s.piecesLeft(left, total),
    hot: offer.state == OfferState.live && offer.isRunningOut,
  );
}
