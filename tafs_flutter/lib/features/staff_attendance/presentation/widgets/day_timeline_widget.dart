import 'package:flutter/material.dart';

import '../../../../core/utils/pkt_format.dart';
import '../../domain/entities/staff_attendance_period.dart';

class DayTimelineWidget extends StatefulWidget {
  final List<Map<String, dynamic>>? segments;
  final List<StaffScan> scans;

  const DayTimelineWidget({
    super.key,
    this.segments,
    required this.scans,
  });

  @override
  State<DayTimelineWidget> createState() => _DayTimelineWidgetState();
}

class _DayTimelineWidgetState extends State<DayTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.35, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  double _toPct(String value) {
    if (value == '00:00') return 0;
    if (value == '24:00') return 100;
    final dt = DateTime.parse(value).toUtc();
    return ((dt.hour * 60 + dt.minute) / 1440) * 100;
  }

  List<_Seg> _buildSegs() {
    final rawSegs = widget.segments;
    if (rawSegs != null && rawSegs.isNotEmpty) {
      final result = <_Seg>[];
      for (final s in rawSegs) {
        final type = s['type'] as String? ?? '';
        final start = s['start'] as String?;
        final end = s['end'] as String?;
        final missing = s['isMissingOut'] == true;
        if (start == null) continue;

        Color color;
        switch (type) {
          case 'WORK':
            color = const Color(0xFF10B981);
            break;
          case 'BREAK':
            color = const Color(0xFF60A5FA);
            break;
          case 'OVERTIME':
            color = const Color(0xFFF59E0B);
            break;
          default:
            color = const Color(0xFFD4D4D8);
        }

        final left = _toPct(start);
        final right = missing ? left + 2.5 : _toPct(end ?? '24:00');
        final width = (right - left).clamp(missing ? 1.5 : 0.5, 100.0);

        result.add(_Seg(
          left: left,
          width: width,
          color: missing ? const Color(0xFFFBBF24) : color,
          missing: missing,
        ));
      }
      if (result.isNotEmpty) return result;
    }

    // Fall back to raw scans
    if (widget.scans.isEmpty) return [];
    final result = <_Seg>[];
    for (var i = 0; i < widget.scans.length; i += 2) {
      final inPkt = toPkt(widget.scans[i].scanTime);
      final inPct = ((inPkt.hour * 60 + inPkt.minute) / 1440) * 100;
      if (i + 1 < widget.scans.length) {
        final outPkt = toPkt(widget.scans[i + 1].scanTime);
        final outPct = ((outPkt.hour * 60 + outPkt.minute) / 1440) * 100;
        result.add(_Seg(
          left: inPct,
          width: (outPct - inPct).clamp(0.5, 100.0),
          color: const Color(0xFF10B981),
        ));
      } else {
        result.add(_Seg(
          left: inPct,
          width: 2.5,
          color: const Color(0xFFFBBF24),
          missing: true,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final segs = _buildSegs();
    final hasMissing = segs.any((s) => s.missing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (segs.isEmpty)
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'No scans recorded',
                style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
              ),
            ),
          )
        else
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (ctx, _) {
              return LayoutBuilder(
                builder: (ctx2, constraints) {
                  final total = constraints.maxWidth;
                  return Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        for (final seg in segs)
                          Positioned(
                            left: (seg.left / 100) * total,
                            width: ((seg.width / 100) * total).clamp(2.0, total),
                            top: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: seg.missing ? _pulseAnim.value : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: seg.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('12 AM', style: TextStyle(fontSize: 9, color: Color(0xFFA1A1AA))),
            Text('6 AM',  style: TextStyle(fontSize: 9, color: Color(0xFFA1A1AA))),
            Text('12 PM', style: TextStyle(fontSize: 9, color: Color(0xFFA1A1AA))),
            Text('6 PM',  style: TextStyle(fontSize: 9, color: Color(0xFFA1A1AA))),
            Text('12 AM', style: TextStyle(fontSize: 9, color: Color(0xFFA1A1AA))),
          ],
        ),
        if (hasMissing) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Missing clock-out',
                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Seg {
  final double left;
  final double width;
  final Color color;
  final bool missing;

  const _Seg({
    required this.left,
    required this.width,
    required this.color,
    this.missing = false,
  });
}
