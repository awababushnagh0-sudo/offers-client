import 'package:kernel/kernel.dart';

import '../../products/domain/product.dart';
import '../../products/presentation/product_view_model.dart';
import '../domain/offer.dart';
import 'offer_draft_view_model.dart';
import 'offer_view_model.dart';

/// The product to post from, and the ended offer it's posted again from.
typedef NewOfferArgs = ({String productId, String? fromOfferId});

/// Posts an offer from a product. Its page has already loaded the product
/// (and the offer it reposts).
class NewOfferViewModel extends OfferDraftViewModel {
  NewOfferViewModel(this.args);

  final NewOfferArgs args;

  late final Product product;

  @override
  String get regularPrice => product.regularPrice;

  @override
  NewOfferState build() {
    product = ref.read(productViewModel(args.productId)).requireValue;
    final fromId = args.fromOfferId;
    return buildForm(
      from: fromId == null
          ? null
          : ref.read(offerViewModel(fromId)).requireValue,
    );
  }

  /// Returns the posted offer, or null when it wasn't posted.
  Future<Offer?> post() async {
    final storeId = startPosting();
    if (storeId == null) return null;
    return postFor(storeId, product.id);
  }
}

final newOfferViewModel = NotifierProvider.autoDispose
    .family<NewOfferViewModel, NewOfferState, NewOfferArgs>(
      NewOfferViewModel.new,
    );
