import 'package:kernel/kernel.dart';
import 'package:stellar/stellar.dart';

import '../../../core/l10n/generated/partner_localizations.dart';
import '../../../core/routes/routes.dart';
import '../../products/presentation/product_photo_view_model.dart';
import '../../products/presentation/widgets/product_photo_field.dart';
import 'quick_offer_view_model.dart';
import 'widgets/offer_fields.dart';

/// Posts an offer for something new in one go: its photo, name and
/// regular price, then the offer. It's saved as a product on the way.
class QuickOfferScreen extends AppView {
  const QuickOfferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = PartnerLocalizations.of(context);
    final state = ref.watch(quickOfferViewModel);
    final viewModel = ref.read(quickOfferViewModel.notifier);
    final uploading = ref.watch(productPhotoViewModel(null)).progress != null;

    Future<void> post() async {
      final offer = await viewModel.post();
      if (offer == null || !context.mounted) return;
      if (ref.read(productPhotoViewModel(null)).failed) {
        SSnack.error(context, s.offerPostedPhotoFailed);
      } else {
        SSnack.success(context, s.offerPosted);
      }
      context.pushReplacement(Routes.offer(offer.id));
    }

    return SScaffold(
      title: s.newOfferTitle,
      scrollable: true,
      bottom: SButton(
        label: s.postOffer,
        onPressed: post,
        loading: state.posting || uploading,
        expand: true,
      ),
      body: SForm(
        form: viewModel.form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.lg,
          children: [
            // A photo that failed to go is sent again with the offer.
            ProductPhotoField(productId: null, onRetry: post),
            SFormSection(
              title: s.productBasicsSection,
              note: s.quickProductNote,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Space.lg,
                children: [
                  STextInput(
                    controlName: 'title',
                    label: s.productTitleLabel,
                    hint: s.productTitleHint,
                  ),
                  STextInput(
                    controlName: 'regular',
                    label: s.regularPriceLabel,
                    kind: TextInputKind.price,
                    helper: s.regularPriceHelper,
                  ),
                  STextInput(
                    controlName: 'description',
                    label: s.descriptionLabel,
                    hint: s.descriptionHint,
                    kind: TextInputKind.multiline,
                    maxLength: 1000,
                  ),
                ],
              ),
            ),
            OfferFields(viewModel: viewModel, state: state),
            if (state.failure case final failure?)
              SText(failureMessage(context, failure), color: SColor.danger),
          ],
        ),
      ),
    );
  }
}
