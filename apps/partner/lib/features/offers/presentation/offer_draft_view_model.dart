import 'dart:async';

import 'package:kernel/kernel.dart';
import 'package:stellar/stellar.dart';

import '../../home/presentation/home_view_model.dart';
import '../../store/domain/current_store.dart';
import '../domain/offer.dart';
import 'offer_form_checks.dart';
import 'offers_view_model.dart';

class NewOfferState {
  const NewOfferState({
    required this.type,
    required this.discount,
    this.branchIds,
    this.posting = false,
    this.noBranch = false,
    this.failure,
  });

  final OfferType type;

  /// The discount the typed price gives, or null while it isn't a price.
  final int? discount;

  /// Null for all the store's branches.
  final Set<String>? branchIds;
  final bool posting;

  /// Every branch was unticked.
  final bool noBranch;
  final AppFailure? failure;
}

/// What both ways of posting an offer share: the offer's fields (its
/// price under the regular one, type, pieces, hold time, per customer and
/// end), its branches, and posting it for a product.
abstract class OfferDraftViewModel extends ViewModel<NewOfferState> {
  late final FormGroup form;

  /// The regular price ("8.000") the offer's must be under; null while
  /// there's none yet (typed on the form, for something new).
  String? get regularPrice;

  /// Builds [form] from the offer's fields and [extra] ones, filled from
  /// [from] when it's posted again; returns the first state.
  NewOfferState buildForm({
    Offer? from,
    Map<String, AbstractControl<Object?>> extra = const {},
  }) {
    final type = from?.type ?? OfferType.limited;
    form = FormGroup({
      ...extra,
      'price': FormControl<String>(
        value: from?.offerPrice,
        validators: [
          Validators.required,
          SValidators.price,
          OfferChecks.belowRegularOf(() => regularPrice),
        ],
      ),
      'type': FormControl<OfferType>(value: type),
      'quantity': FormControl<String>(
        value: from?.totalQuantity?.toString(),
        validators: [SValidators.wholeNumberBetween(1, 10000)],
      ),
      'hold': FormControl<String>(
        value: '${from?.claimWindowMinutes ?? 60}',
        validators: [SValidators.wholeNumberBetween(15, 240)],
      ),
      'perCustomer': FormControl<String>(
        value: '${from?.maxPerUser ?? 1}',
        validators: [
          Validators.required,
          SValidators.wholeNumberBetween(1, 10),
        ],
      ),
      'endsAt': FormControl<DateTime>(
        value: OfferChecks.defaultEnd(),
        validators: [Validators.required, OfferChecks.endsAt],
      ),
    });
    _requireLimitedFields(type);
    final prices = form
        .control('price')
        .valueChanges
        .listen((_) => refreshDiscount());
    ref.onDispose(() {
      unawaited(prices.cancel());
      form.dispose();
    });
    return NewOfferState(
      type: type,
      discount: _discount(),
      branchIds: from?.branchIds.toSet(),
    );
  }

  void setType(OfferType type) {
    _requireLimitedFields(type);
    state = NewOfferState(
      type: type,
      discount: state.discount,
      branchIds: state.branchIds,
    );
  }

  /// Ticks or unticks a branch; [all] are the store's active branches.
  void toggleBranch(String id, List<String> all) {
    final chosen = {...(state.branchIds ?? all.toSet())};
    if (!chosen.remove(id)) chosen.add(id);
    state = NewOfferState(
      type: state.type,
      discount: state.discount,
      branchIds: chosen.length == all.length ? null : chosen,
    );
  }

  /// After the offer's price or the regular price changes.
  void refreshDiscount() => state = NewOfferState(
    type: state.type,
    discount: _discount(),
    branchIds: state.branchIds,
  );

  /// The store to post in, once everything's filled in right; null, with
  /// what's wrong marked, otherwise. Shows it's posting.
  String? startPosting() {
    if (state.posting) return null;
    final branchIds = state.branchIds;
    final noBranch = branchIds != null && branchIds.isEmpty;
    if (form.invalid || noBranch) {
      form.markAllAsTouched();
      state = NewOfferState(
        type: state.type,
        discount: state.discount,
        branchIds: branchIds,
        noBranch: noBranch,
      );
      return null;
    }
    final storeId = ref.read(currentStoreProvider)?.storeId;
    if (storeId == null) return null;
    _setPosting(posting: true);
    return storeId;
  }

  /// Ends posting with why it failed.
  void failPosting(AppFailure failure) => _setPosting(failure: failure);

  /// Posts the offer for [productId]; returns it, or null when it wasn't
  /// posted (the failure is in the state).
  Future<Offer?> postFor(String storeId, String productId) async {
    final limited = state.type == OfferType.limited;
    final branchIds = state.branchIds;
    final result = await ref
        .read(offerRepositoryProvider)
        .create(
          storeId,
          NewOffer(
            productId: productId,
            offerPrice: parsePrice(form.control('price').value as String)!,
            type: state.type,
            totalQuantity: limited ? _number('quantity') : null,
            claimWindowMinutes: limited ? _number('hold') : null,
            maxPerUser: _number('perCustomer')!,
            endsAt: form.control('endsAt').value as DateTime,
            branchIds: branchIds?.toList(),
          ),
        );
    if (!ref.mounted) return null;
    _setPosting(failure: result.failureOrNull);
    if (result.isOk) {
      ref
        ..invalidate(offersViewModel)
        ..invalidate(homeViewModel);
    }
    return result.valueOrNull;
  }

  void _setPosting({bool posting = false, AppFailure? failure}) =>
      state = NewOfferState(
        type: state.type,
        discount: state.discount,
        branchIds: state.branchIds,
        posting: posting,
        failure: failure,
      );

  /// Pieces and the hold time only count for limited offers.
  void _requireLimitedFields(OfferType type) {
    final limited = type == OfferType.limited;
    form
      ..control('quantity').setValidators([
        if (limited) Validators.required,
        SValidators.wholeNumberBetween(1, 10000),
      ], autoValidate: true)
      ..control('hold').setValidators([
        if (limited) Validators.required,
        SValidators.wholeNumberBetween(15, 240),
      ], autoValidate: true);
  }

  int? _discount() {
    final value = form.control('price').value;
    final price = value is String ? parsePrice(value) : null;
    final regular = regularPrice;
    return price == null || regular == null
        ? null
        : discountPercent(original: regular, offer: price);
  }

  int? _number(String name) =>
      SValidators.wholeNumber(form.control(name).value);
}
