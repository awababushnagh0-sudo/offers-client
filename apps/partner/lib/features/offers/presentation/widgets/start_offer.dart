import 'dart:async';

import 'package:kernel/kernel.dart';
import 'package:stellar/stellar.dart';

import '../../../../core/l10n/generated/partner_localizations.dart';
import '../../../../core/routes/routes.dart';

enum _Start { fromProducts, somethingNew }

/// Asks what the offer is on: one of the store's products, or something
/// new (saved as a product on the way). Then opens that page.
Future<void> startOffer(BuildContext context) async {
  final s = PartnerLocalizations.of(context);
  final start = await SSheet.actions<_Start>(
    context,
    title: s.startOfferTitle,
    actions: [
      SheetAction(
        value: _Start.fromProducts,
        icon: SIcons.products,
        label: s.fromMyProducts,
        hint: s.fromMyProductsHint,
      ),
      SheetAction(
        value: _Start.somethingNew,
        icon: SIcons.add,
        label: s.somethingNew,
        hint: s.somethingNewHint,
      ),
    ],
  );
  if (!context.mounted) return;
  switch (start) {
    case _Start.fromProducts:
      unawaited(context.push(Routes.chooseOfferProduct));
    case _Start.somethingNew:
      unawaited(context.push(Routes.quickOffer));
    case null:
      break;
  }
}
