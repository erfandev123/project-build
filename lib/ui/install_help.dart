import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/platform_service.dart';
import '../theme/borno_theme.dart';
import 'widgets.dart';

/// Installs Borno when the browser exposes an install prompt; otherwise opens
/// a short, platform-specific guide. No fake "installed" state.
Future<void> installBorno(BuildContext context) async {
  if (PlatformService.pwaStandalone) {
    showBornoToast(context, 'Borno ইতিমধ্যে হোম স্ক্রিনে ইনস্টল করা আছে।');
    return;
  }

  if (PlatformService.pwaCanInstall && PlatformService.installPwa()) {
    showBornoToast(
      context,
      'ব্রাউজারের ইনস্টল প্রম্পট খুলেছে — “Install” চাপুন।',
    );
    return;
  }

  await showInstallHelpSheet(context);
}

Future<void> showInstallHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xC2050B08),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _InstallSheet(),
  );
}

class _InstallSheet extends StatelessWidget {
  const _InstallSheet();

  Future<void> _copyLink(BuildContext context) async {
    final url = Uri.base.replace(fragment: '').toString();
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        showBornoToast(
          context,
          'লিংক কপি হয়েছে — ব্রাউজারে খুলে ইনস্টল করুন।',
        );
      }
    } catch (_) {
      if (context.mounted) {
        showBornoToast(context, 'লিংক কপি করা যায়নি।');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = PlatformService.pwaStandalone;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
            decoration: BoxDecoration(
              color: BornoColors.panel,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: BornoColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 48,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: const Color(0x2EFFFFFF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const BornoMark(size: 46, radiusFactor: 0.27),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      installed
                                          ? 'Borno ইনস্টল করা আছে'
                                          : 'Borno হোম স্ক্রিনে নিন',
                                      style: bengali(
                                        size: 20,
                                        weight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      installed
                                          ? 'অ্যাপের মতো খুলুন—ঠিকানা বার ছাড়াই।'
                                          : 'অ্যাপের মতো খুলুন, নেট ছাড়াই টাইপ করুন।',
                                      style: bengali(
                                        size: 11.5,
                                        weight: FontWeight.w400,
                                        color: BornoColors.muted,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _CloseButton(
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
                            decoration: BoxDecoration(
                              color: const Color(0x06FFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x14FFFFFF),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  size: 16,
                                  color: BornoColors.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    Uri.base.replace(fragment: '').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10.5,
                                      height: 1.2,
                                      fontWeight: FontWeight.w500,
                                      color: BornoColors.textSoft,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextButton(
                                  onPressed: () => _copyLink(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: BornoColors.lime,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontFamily: 'HindSiliguri',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('কপি'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (installed)
                            _InstalledCard()
                          else ...[
                            const _PlatformGuide(
                              icon: Icons.android_rounded,
                              title: 'Android · Chrome',
                              lines: [
                                'উপরে ডান দিকের ⋮ মেনু চাপুন।',
                                '“Add to Home screen” বা “Install app” বেছে নিন।',
                                'নিশ্চিত করতে Install চাপুন।',
                              ],
                            ),
                            const SizedBox(height: 9),
                            const _PlatformGuide(
                              icon: Icons.phone_iphone_rounded,
                              title: 'iPhone / iPad · Safari',
                              lines: [
                                'নিচের Share (□↑) আইকন চাপুন।',
                                '“Add to Home Screen” বেছে নিন।',
                                'উপরে ডান দিকে Add চাপুন।',
                              ],
                            ),
                            const SizedBox(height: 9),
                            const _PlatformGuide(
                              icon: Icons.laptop_mac_rounded,
                              title: 'Desktop · Chrome / Edge',
                              lines: [
                                'অ্যাড্রেস বারের ডান প্রান্তে ইনস্টল আইকন চাপুন।',
                                'অথবা মেনু থেকে “Install Borno” বেছে নিন।',
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                            decoration: BoxDecoration(
                              color: BornoColors.lime.withValues(alpha: 0.055),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: BornoColors.lime.withValues(alpha: 0.16),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  size: 15,
                                  color: BornoColors.lime,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'প্রথমবার পুরোপুরি লোড হওয়ার পর কীবোর্ড, সাজেশন আর থিম ইন্টারনেট ছাড়াই কাজ করে। ভয়েসের জন্য ডিভাইসে বাংলা স্পিচ প্যাক থাকলে সেটিও অফলাইনে চলে।',
                                    style: TextStyle(
                                      fontFamily: 'HindSiliguri',
                                      fontSize: 10.5,
                                      height: 1.5,
                                      color: BornoColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () => _copyLink(context),
                            icon: const Icon(
                              Icons.content_copy_rounded,
                              size: 16,
                            ),
                            label: const Text('লিংক কপি করুন'),
                            style: FilledButton.styleFrom(
                              backgroundColor: BornoColors.lime,
                              foregroundColor: BornoColors.onLime,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'HindSiliguri',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'নোট: এটা একটি ওয়েব অ্যাপ। Android-এর সিস্টেম-ওয়াইড কীবোর্ড হিসেবে ব্যবহার করতে হলে আলাদা নেটিভ IME অ্যাপ লাগবে।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 9.5,
                              height: 1.5,
                              color: BornoColors.mutedDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstalledCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: BornoColors.lime.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BornoColors.lime.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BornoColors.lime,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 20,
              color: BornoColors.onLime,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'হোম স্ক্রিন থেকে খুলুন',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BornoColors.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ঠিকানা বার আর ট্যাব ছাড়াই পুরো স্ক্রিনে কীবোর্ড।',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 10.5,
                    height: 1.45,
                    color: BornoColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformGuide extends StatelessWidget {
  const _PlatformGuide({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: const Color(0x04FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Icon(icon, size: 16, color: BornoColors.textSoft),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: BornoColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == lines.length - 1 ? 0 : 3,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: BornoColors.mutedDeep,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            lines[i],
                            style: const TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 10.5,
                              height: 1.45,
                              color: BornoColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      padding: const EdgeInsets.all(8),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x0DFFFFFF),
        side: const BorderSide(color: Color(0x18FFFFFF)),
      ),
      icon: const Icon(Icons.close_rounded, color: BornoColors.muted),
    );
  }
}
