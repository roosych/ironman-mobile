import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../application/policies_notifier.dart';
import '../application/policies_state.dart';
import '../domain/policy.dart';
import '../../settings/application/locale_notifier.dart';
import '../../../shared/widgets/language_selector.dart';

class PolicyScreen extends ConsumerStatefulWidget {
  final String? initialType; // privacy, terms, data_processing, cookies
  final String? initialLanguage; // en, ru, az

  const PolicyScreen({
    super.key,
    this.initialType,
    this.initialLanguage,
  });

  @override
  ConsumerState<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends ConsumerState<PolicyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializePolicy();
      _isInitialized = true;
    }
  }

  void _initializePolicy() {
    final notifier = ref.read(policiesProvider.notifier);

    // Initialize with parameters or defaults
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await notifier.initialize();

      // Override with initial parameters if provided
      if (widget.initialType != null) {
        final type = PolicyType.allTypes.firstWhere(
          (t) => t.value == widget.initialType,
          orElse: () => PolicyType.privacy,
        );
        notifier.selectType(type);

        // Update tab controller to match selected type
        final tabIndex = PolicyType.allTypes.indexOf(type);
        if (tabIndex >= 0 && _tabController.length > tabIndex) {
          _tabController.animateTo(tabIndex);
        }
      }

      if (widget.initialLanguage != null) {
        final language = PolicyLanguage.allLanguages.firstWhere(
          (l) => l.code == widget.initialLanguage,
          orElse: () => PolicyLanguage.english,
        );
        notifier.selectLanguage(language);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(policiesProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient overlay
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Main content
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const LanguageSelector(),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Theme.of(context).primaryColor,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    onTap: (index) {
                      if (index < PolicyType.allTypes.length) {
                        final type = PolicyType.allTypes[index];
                        ref.read(policiesProvider.notifier).selectType(type);
                      }
                    },
                    tabs: PolicyType.allTypes.map((type) {
                      final currentLocale = ref.read(localeProvider.notifier).getLocaleForApi();
                      final localizedName = ref.read(policiesProvider.notifier)
                          .getLocalizedTypeName(type, currentLocale);
                      return Tab(text: localizedName);
                    }).toList(),
                  ),
                ),
              ),
            ),
            body: Container(
              color: Colors.grey.shade50,
              child: _buildBody(context, state, localizations),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBody(BuildContext context, PoliciesState state, AppLocalizations localizations) {
    if (state.isCurrentPolicyLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return _buildErrorState(context, state.error!, localizations);
    }

    final policy = state.currentPolicy;
    if (policy == null) {
      return _buildNotAvailableState(context, localizations);
    }

    return _buildPolicyContent(context, policy, localizations);
  }

  Widget _buildErrorState(BuildContext context, String error, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(policiesProvider.notifier).refreshCurrentPolicy();
              },
              child: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAvailableState(BuildContext context, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedImageNotFound01,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              localizations.policy_not_available,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyContent(BuildContext context, Policy policy, AppLocalizations localizations) {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 100.0, // Дополнительный отступ снизу для системных кнопок
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            policy.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          // Effective date
          Text(
            'Действует с: ${_formatDate(policy.effectiveDate)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          // HTML Content
          Html(
            data: policy.content,
            style: {
              "body": Style(
                fontSize: FontSize(16),
                lineHeight: LineHeight.number(1.6),
                color: Colors.black,
                fontFamily: 'system',
              ),
              "h1": Style(
                fontSize: FontSize(24),
                fontWeight: FontWeight.bold,
                color: Colors.black,
                margin: Margins.only(top: 24, bottom: 12),
              ),
              "h2": Style(
                fontSize: FontSize(20),
                fontWeight: FontWeight.bold,
                color: Colors.black,
                margin: Margins.only(top: 20, bottom: 10),
              ),
              "h3": Style(
                fontSize: FontSize(18),
                fontWeight: FontWeight.w600,
                color: Colors.black,
                margin: Margins.only(top: 16, bottom: 8),
              ),
              "p": Style(
                margin: Margins.only(bottom: 12),
                textAlign: TextAlign.left,
              ),
              "ul": Style(
                margin: Margins.only(top: 8, bottom: 16, left: 16),
              ),
              "ol": Style(
                margin: Margins.only(top: 8, bottom: 16, left: 16),
              ),
              "li": Style(
                margin: Margins.only(bottom: 4),
              ),
              "a": Style(
                color: Theme.of(context).primaryColor,
                textDecoration: TextDecoration.underline,
              ),
              "blockquote": Style(
                border: Border(left: BorderSide(color: Colors.grey.shade300, width: 4)),
                padding: HtmlPaddings.only(left: 16),
                margin: Margins.only(top: 8, bottom: 16),
                backgroundColor: Colors.grey.shade50,
              ),
            },
          ),
          const SizedBox(height: 32),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Информация о документе',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Тип:', policy.typeName),
                _buildInfoRow('Язык:', policy.language.toUpperCase()),
                _buildInfoRow('Дата создания:', _formatDate(policy.createdAt)),
                _buildInfoRow('Последнее обновление:', _formatDate(policy.updatedAt)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}