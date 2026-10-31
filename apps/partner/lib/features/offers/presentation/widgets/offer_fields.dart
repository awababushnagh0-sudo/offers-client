import 'package:kernel/kernel.dart';
import 'package:stellar/stellar.dart';

import '../../../../core/l10n/generated/partner_localizations.dart';
import '../../../store/domain/store.dart';
import '../../../store/presentation/store_view_model.dart';
import '../../domain/offer.dart';
import '../offer_draft_view_model.dart';
import '../offer_form_checks.dart';

/// The offer's part of a posting form, on two panels: the deal (its
/// price, type, pieces, hold time and per customer), then when it ends
/// and, with several branches, where.
class OfferFields extends AppView {
  const OfferFields({required this.viewModel, required this.state, super.key});

  final OfferDraftViewModel viewModel;
  final NewOfferState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = PartnerLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final regularPrice = viewModel.regularPrice;
    final regular = regularPrice == null
        ? ''
        : formatPrice(regularPrice, languageCode: language);
    final discount = state.discount;
    // The store's branches, to choose from when there are several.
    final branches = [
      for (final branch
          in ref.watch(storeViewModel).value?.branches ?? const <Branch>[])
        if (branch.isActive) branch,
    ];
    final branchIds = [for (final branch in branches) branch.id];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.lg,
      children: [
        SFormSection(
          title: s.offerSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.lg,
            children: [
              STextInput(
                controlName: 'price',
                label: s.offerPriceLabel,
                kind: TextInputKind.price,
                helper: discount != null && discount > 0
                    ? s.discountHelper(discount)
                    : null,
                validationMessages: {
                  OfferChecks.belowRegularKey: (_) =>
                      s.offerPriceTooHigh(regular),
                },
              ),
              SChoiceInput<OfferType>(
                controlName: 'type',
                label: s.offerTypeLabel,
                options: [
                  SelectOption(OfferType.limited, s.limitedType),
                  SelectOption(OfferType.unlimited, s.unlimitedType),
                ],
                onChanged: viewModel.setType,
              ),
              if (state.type == OfferType.limited) ...[
                STextInput(
                  controlName: 'quantity',
                  label: s.quantityLabel,
                  kind: TextInputKind.number,
                ),
                STextInput(
                  controlName: 'hold',
                  label: s.holdLabel,
                  kind: TextInputKind.number,
                  helper: s.holdHelper,
                ),
              ],
              STextInput(
                controlName: 'perCustomer',
                label: s.perCustomerLabel,
                kind: TextInputKind.number,
                helper: s.perCustomerHelper,
              ),
            ],
          ),
        ),
        SFormSection(
          title: branches.length > 1 ? s.whenAndWhereSection : s.whenSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.lg,
            children: [
              SDateTimeInput(
                controlName: 'endsAt',
                label: s.endsLabel,
                firstDate: today,
                lastDate: today.add(OfferChecks.maxDuration),
                presets: endPresets(s),
                validationMessages: endMessages(s),
              ),
              if (branches.length > 1) ...[
                SListGroup(
                  title: s.branchesTitle,
                  children: [
                    for (final branch in branches)
                      SListTile(
                        title: branch.name,
                        trailing: SIcon(
                          state.branchIds?.contains(branch.id) ?? true
                              ? SIcons.selected
                              : SIcons.unselected,
                          color: SColor.primary,
                        ),
                        onTap: () =>
                            viewModel.toggleBranch(branch.id, branchIds),
                      ),
                  ],
                ),
                if (state.noBranch)
                  SText(s.chooseABranch, color: SColor.danger),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One-tap end times: tonight (while it's still to come), tomorrow night,
/// in 3 days, in a week, all at 23:00.
List<DateTimePreset> endPresets(PartnerLocalizations s) {
  final now = DateTime.now();
  DateTime night(int days) => DateTime(now.year, now.month, now.day + days, 23);
  return [
    if (night(0).isAfter(now)) DateTimePreset(s.endsTonight, night(0)),
    DateTimePreset(s.endsTomorrow, night(1)),
    DateTimePreset(s.endsIn3Days, night(3)),
    DateTimePreset(s.endsInAWeek, night(7)),
  ];
}

Map<String, String Function(Object)> endMessages(PartnerLocalizations s) => {
  OfferChecks.endsInPastKey: (_) => s.endsInPast,
  OfferChecks.endsTooLateKey: (_) => s.endsTooLate,
};
