import 'package:fastingapp/presentation/mochi_world/model/mochi_world_stage.dart';
import 'package:flutter/foundation.dart';

// Yerleşim tablosu referans sahnelerden (mochi-world-1…10, 941×1672)
// ölçülmüştür. Her elementin adada sabit bir yeri vardır; seviye arttıkça
// yalnızca belirir, büyür ya da türü değişir — sağlık bozulunca da solgun
// hâline döner. Hiçbir elementin tabanı adanın arka kenarının üstünde
// kalmaz (havada durmaz).

/// Adanın sağlığı: kullanıcı aksattıkça ada solar, sonra kurur.
enum MochiHealth { thriving, wilting, drought }

/// Elementleri açan dünya bölgeleri.
enum MochiZone { forest, lake, summit, garden }

/// En yüksek büyüme seviyesi (0 = boş ada, 4 = cennet).
const kMochiMaxLevel = 4;

/// Adaya yerleştirilebilen sprite türleri.
enum MochiElementKind {
  tree('tree', 624 / 640),
  fruitTree('fruit_tree', 640 / 605),
  treeRound('tree_round', 640 / 558),
  treeSoft('tree_soft', 640 / 558),
  treeFairy('tree_fairy', 635 / 640),
  treePale('tree_pale', 640 / 596),
  treeBare('tree_bare', 621 / 640),
  saplingWilting('sapling_wilting', 640 / 538),
  flowerYellow('flower_yellow', 640 / 484),
  flowerClay('flower_clay', 640 / 501),
  flowerCream('flower_cream', 640 / 532),
  flowerPeach('flower_peach', 640 / 524),
  flowerOrange('flower_orange', 640 / 540),
  flowerWilted('flower_wilted', 565 / 640),
  flowers('flowers', 375 / 640),
  pondLily('pond_lily', 323 / 640),
  pondDrying('pond_drying', 386 / 640),
  pondDried('pond_dried', 371 / 640),
  crackedPatch('cracked_patch', 405 / 640),
  shrubDry('shrub_dry', 506 / 640),
  mountain('mountain', 445 / 640),
  waterfall('waterfall', 640 / 520),
  fence('fence', 444 / 640),
  bench('bench', 537 / 640),
  lantern('lantern', 640 / 385),
  lily('lily', 358 / 640);

  const MochiElementKind(this.file, this.aspect);

  final String file;

  /// Kırpılmış sprite'ın yükseklik / genişlik oranı.
  final double aspect;

  String get asset => 'assets/images/mochi/$file.webp';

  /// Sağlıklı ağaçlar (solunca solgun/çıplak ağaca döner).
  bool get isHealthyTree => switch (this) {
    tree || fruitTree || treeRound || treeSoft || treeFairy => true,
    _ => false,
  };

  bool get isTree =>
      isHealthyTree ||
      this == treePale ||
      this == treeBare ||
      this == saplingWilting;

  /// Tek tek dikilmiş çiçekler.
  bool get isSingleFlower => switch (this) {
    flowerYellow ||
    flowerClay ||
    flowerCream ||
    flowerPeach ||
    flowerOrange ||
    flowerWilted => true,
    _ => false,
  };

  bool get isPond =>
      this == pondLily || this == pondDrying || this == pondDried;

  /// Kuru versiyonu olmayan, solunca rengi soluklaşan elementler.
  bool get fadesWhenUnwell => switch (this) {
    flowers ||
    fence ||
    bench ||
    lantern ||
    mountain ||
    waterfall ||
    lily => true,
    _ => false,
  };
}

/// Bir elementin belirli bir seviyedeki görünümü.
@immutable
final class MochiElementSpec {
  const MochiElementSpec(this.kind, this.width, {this.x, this.y});

  final MochiElementKind kind;

  /// Görsel piksel uzayında genişlik.
  final double width;

  /// Bu seviyeye özel konum (yoksa elementin ana konumu). Çiçekler seviye
  /// atlarken yeni yerlerine kayar.
  final double? x;
  final double? y;
}

/// Adadaki tek bir element yuvası.
@immutable
final class MochiElementDef {
  const MochiElementDef({
    required this.key,
    required this.zone,
    required this.x,
    required this.y,
    required this.levels,
    this.flip = false,
    this.bare = false,
    this.saplingUntil = -1,
    this.droughtOnly = false,
    this.decal = false,
  });

  /// Seviyeler ve durumlar arasında aynı kalan kimlik.
  final String key;
  final MochiZone zone;

  /// Zemine bastığı alt-orta nokta (görsel pikseli).
  final double x;
  final double y;

  /// Seviye -> görünüm; listede olmayan seviyede element yoktur.
  final Map<int, MochiElementSpec> levels;

  /// Yatay aynalı çizilir (çit patika boyunca aşağı insin diye).
  final bool flip;

  /// Solunca solgun değil çıplak ağaca döner.
  final bool bare;

  /// Bu seviyeye kadar fidandır; solunca "solan fidan" olur.
  final int saplingUntil;

  /// Yalnızca kuraklıkta görünür (kuru çalı, çatlak toprak).
  final bool droughtOnly;

  /// Zemin dokusu: her şeyin altında çizilir.
  final bool decal;
}

/// Ekrana çizilecek, çözümlenmiş tek yerleşim.
@immutable
final class MochiPlacement {
  const MochiPlacement({
    required this.key,
    required this.kind,
    required this.x,
    required this.y,
    required this.width,
    required this.flip,
    required this.faded,
    required this.decal,
  });

  final String key;
  final MochiElementKind kind;
  final double x;
  final double y;
  final double width;
  final bool flip;

  /// Renkleri soluklaşmış (solmuş ama kuru sprite'ı olmayan element).
  final bool faded;
  final bool decal;
}

/// Bir dünya durumu: büyüme seviyesi + sağlık.
typedef MochiWorldState = ({int level, MochiHealth health});

const List<MochiElementDef> kMochiElements = [
  MochiElementDef(
    key: 'b1',
    zone: MochiZone.forest,
    x: 255,
    y: 712,
    levels: {
      2: MochiElementSpec(MochiElementKind.treeFairy, 153),
      3: MochiElementSpec(MochiElementKind.treeFairy, 180),
      4: MochiElementSpec(MochiElementKind.treeFairy, 180),
    },
    bare: true,
  ),
  MochiElementDef(
    key: 'b2',
    zone: MochiZone.forest,
    x: 350,
    y: 724,
    levels: {
      2: MochiElementSpec(MochiElementKind.treeRound, 138),
      3: MochiElementSpec(MochiElementKind.treeRound, 162),
      4: MochiElementSpec(MochiElementKind.treeRound, 162),
    },
  ),
  MochiElementDef(
    key: 'b3',
    zone: MochiZone.forest,
    x: 435,
    y: 716,
    levels: {
      3: MochiElementSpec(MochiElementKind.treeSoft, 132),
      4: MochiElementSpec(MochiElementKind.treeSoft, 132),
    },
  ),
  MochiElementDef(
    key: 'b4',
    zone: MochiZone.forest,
    x: 168,
    y: 782,
    levels: {
      2: MochiElementSpec(MochiElementKind.treeSoft, 128),
      3: MochiElementSpec(MochiElementKind.treeSoft, 150),
      4: MochiElementSpec(MochiElementKind.fruitTree, 156),
    },
  ),
  MochiElementDef(
    key: 'm1',
    zone: MochiZone.forest,
    x: 92,
    y: 838,
    levels: {
      2: MochiElementSpec(MochiElementKind.treeRound, 148),
      3: MochiElementSpec(MochiElementKind.treeRound, 174),
      4: MochiElementSpec(MochiElementKind.fruitTree, 160, x: 72, y: 866),
    },
  ),
  MochiElementDef(
    key: 'm2',
    zone: MochiZone.forest,
    x: 222,
    y: 772,
    levels: {
      2: MochiElementSpec(MochiElementKind.treeRound, 143),
      3: MochiElementSpec(MochiElementKind.treeRound, 168),
      4: MochiElementSpec(MochiElementKind.treeRound, 168),
    },
  ),
  MochiElementDef(
    key: 'm3',
    zone: MochiZone.forest,
    x: 312,
    y: 768,
    levels: {
      3: MochiElementSpec(MochiElementKind.treeFairy, 144),
      4: MochiElementSpec(MochiElementKind.fruitTree, 150),
    },
    bare: true,
  ),
  MochiElementDef(
    key: 'm4',
    zone: MochiZone.forest,
    x: 400,
    y: 760,
    levels: {
      3: MochiElementSpec(MochiElementKind.treeRound, 114),
      4: MochiElementSpec(MochiElementKind.treeRound, 114),
    },
  ),
  MochiElementDef(
    key: 'n1',
    zone: MochiZone.forest,
    x: 52,
    y: 905,
    levels: {
      3: MochiElementSpec(MochiElementKind.treeSoft, 132),
      4: MochiElementSpec(MochiElementKind.treeSoft, 132),
    },
  ),
  MochiElementDef(
    key: 'sap-a',
    zone: MochiZone.forest,
    x: 150,
    y: 868,
    levels: {
      1: MochiElementSpec(MochiElementKind.treeRound, 70),
      2: MochiElementSpec(MochiElementKind.treeRound, 153),
      3: MochiElementSpec(MochiElementKind.treeRound, 180),
      4: MochiElementSpec(MochiElementKind.treeRound, 150, x: 92, y: 905),
    },
    saplingUntil: 1,
  ),
  MochiElementDef(
    key: 'sap-b',
    zone: MochiZone.forest,
    x: 236,
    y: 828,
    levels: {
      1: MochiElementSpec(MochiElementKind.treeRound, 60),
      2: MochiElementSpec(MochiElementKind.treeFairy, 110),
      3: MochiElementSpec(MochiElementKind.treeFairy, 130),
    },
    saplingUntil: 1,
  ),
  MochiElementDef(
    key: 'sap-c',
    zone: MochiZone.forest,
    x: 198,
    y: 898,
    levels: {1: MochiElementSpec(MochiElementKind.treeRound, 46)},
    saplingUntil: 1,
  ),
  MochiElementDef(
    key: 's1',
    zone: MochiZone.forest,
    x: 508,
    y: 724,
    levels: {
      3: MochiElementSpec(MochiElementKind.treeRound, 62),
      4: MochiElementSpec(MochiElementKind.treeRound, 62),
    },
    bare: true,
  ),
  MochiElementDef(
    key: 's2',
    zone: MochiZone.forest,
    x: 618,
    y: 712,
    levels: {
      3: MochiElementSpec(MochiElementKind.treeRound, 50),
      4: MochiElementSpec(MochiElementKind.treeRound, 50),
    },
  ),
  MochiElementDef(
    key: 's3',
    zone: MochiZone.forest,
    x: 812,
    y: 794,
    levels: {
      3: MochiElementSpec(MochiElementKind.treeRound, 60),
      4: MochiElementSpec(MochiElementKind.treeRound, 60),
    },
    bare: true,
  ),
  MochiElementDef(
    key: 'center',
    zone: MochiZone.forest,
    x: 458,
    y: 850,
    levels: {
      2: MochiElementSpec(MochiElementKind.treeRound, 112),
      3: MochiElementSpec(MochiElementKind.tree, 210),
      4: MochiElementSpec(MochiElementKind.tree, 300),
    },
    saplingUntil: 2,
  ),
  MochiElementDef(
    key: 'mountain',
    zone: MochiZone.summit,
    x: 0,
    y: 0,
    levels: {
      3: MochiElementSpec(MochiElementKind.mountain, 384, x: 531, y: 712),
      4: MochiElementSpec(MochiElementKind.mountain, 561, x: 569, y: 712),
    },
  ),
  MochiElementDef(
    key: 'lily',
    zone: MochiZone.lake,
    x: 662,
    y: 848,
    levels: {1: MochiElementSpec(MochiElementKind.lily, 46)},
  ),
  MochiElementDef(
    key: 'pond',
    zone: MochiZone.lake,
    x: 698,
    y: 910,
    levels: {
      2: MochiElementSpec(MochiElementKind.pondLily, 340),
      3: MochiElementSpec(MochiElementKind.pondLily, 400, x: 690, y: 912),
      4: MochiElementSpec(MochiElementKind.pondLily, 440, x: 680, y: 915),
    },
  ),
  MochiElementDef(
    key: 'waterfall',
    zone: MochiZone.lake,
    x: 638,
    y: 847,
    levels: {4: MochiElementSpec(MochiElementKind.waterfall, 342)},
  ),
  MochiElementDef(
    key: 'bench',
    zone: MochiZone.garden,
    x: 196,
    y: 792,
    levels: {4: MochiElementSpec(MochiElementKind.bench, 80)},
  ),
  MochiElementDef(
    key: 'lantern-a',
    zone: MochiZone.garden,
    x: 0,
    y: 0,
    levels: {4: MochiElementSpec(MochiElementKind.lantern, 72, x: 180, y: 886)},
  ),
  MochiElementDef(
    key: 'lantern-b',
    zone: MochiZone.garden,
    x: 0,
    y: 0,
    levels: {4: MochiElementSpec(MochiElementKind.lantern, 72, x: 142, y: 926)},
  ),
  MochiElementDef(
    key: 'lantern-c',
    zone: MochiZone.garden,
    x: 0,
    y: 0,
    levels: {
      4: MochiElementSpec(MochiElementKind.lantern, 72, x: 400, y: 1082),
    },
  ),
  MochiElementDef(
    key: 'fence-a',
    zone: MochiZone.garden,
    x: 224,
    y: 952,
    levels: {
      3: MochiElementSpec(MochiElementKind.fence, 160),
      4: MochiElementSpec(MochiElementKind.fence, 160),
    },
    flip: true,
  ),
  MochiElementDef(
    key: 'fence-b',
    zone: MochiZone.garden,
    x: 338,
    y: 1014,
    levels: {
      3: MochiElementSpec(MochiElementKind.fence, 160),
      4: MochiElementSpec(MochiElementKind.fence, 160),
    },
    flip: true,
  ),
  MochiElementDef(
    key: 'bed-front',
    zone: MochiZone.garden,
    x: 400,
    y: 872,
    levels: {4: MochiElementSpec(MochiElementKind.flowers, 150)},
  ),
  MochiElementDef(
    key: 'fl0',
    zone: MochiZone.garden,
    x: 801,
    y: 838,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerPeach, 58, x: 801, y: 838),
      2: MochiElementSpec(MochiElementKind.flowerClay, 62, x: 760, y: 800),
    },
  ),
  MochiElementDef(
    key: 'fl1',
    zone: MochiZone.garden,
    x: 792,
    y: 877,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerCream, 58, x: 792, y: 877),
      2: MochiElementSpec(MochiElementKind.flowerYellow, 62, x: 818, y: 916),
      3: MochiElementSpec(MochiElementKind.flowerYellow, 68, x: 820, y: 916),
    },
  ),
  MochiElementDef(
    key: 'fl2',
    zone: MochiZone.garden,
    x: 837,
    y: 899,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerClay, 58, x: 837, y: 899),
      2: MochiElementSpec(MochiElementKind.flowerClay, 62, x: 855, y: 858),
    },
  ),
  MochiElementDef(
    key: 'fl3',
    zone: MochiZone.garden,
    x: 765,
    y: 934,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerYellow, 58, x: 765, y: 934),
      2: MochiElementSpec(MochiElementKind.flowerCream, 62, x: 769, y: 961),
      3: MochiElementSpec(MochiElementKind.flowerCream, 68, x: 772, y: 965),
      4: MochiElementSpec(MochiElementKind.flowerClay, 72, x: 770, y: 974),
    },
  ),
  MochiElementDef(
    key: 'fl4',
    zone: MochiZone.garden,
    x: 847,
    y: 938,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerOrange, 58, x: 847, y: 938),
      2: MochiElementSpec(MochiElementKind.flowerPeach, 62, x: 875, y: 906),
      3: MochiElementSpec(MochiElementKind.flowerPeach, 68, x: 872, y: 911),
      4: MochiElementSpec(MochiElementKind.flowerClay, 72, x: 875, y: 919),
    },
  ),
  MochiElementDef(
    key: 'fl5',
    zone: MochiZone.garden,
    x: 870,
    y: 982,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerPeach, 58, x: 870, y: 982),
      2: MochiElementSpec(MochiElementKind.flowerPeach, 62, x: 852, y: 987),
      3: MochiElementSpec(MochiElementKind.flowerPeach, 68, x: 865, y: 991),
      4: MochiElementSpec(MochiElementKind.flowerPeach, 72, x: 880, y: 954),
    },
  ),
  MochiElementDef(
    key: 'fl6',
    zone: MochiZone.garden,
    x: 738,
    y: 983,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerCream, 58, x: 738, y: 983),
      2: MochiElementSpec(MochiElementKind.flowerYellow, 62, x: 737, y: 991),
      3: MochiElementSpec(MochiElementKind.flowerClay, 68, x: 747, y: 976),
      4: MochiElementSpec(MochiElementKind.flowerPeach, 72, x: 800, y: 1099),
    },
  ),
  MochiElementDef(
    key: 'fl7',
    zone: MochiZone.garden,
    x: 801,
    y: 996,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerClay, 58, x: 801, y: 996),
      2: MochiElementSpec(MochiElementKind.flowerClay, 62, x: 827, y: 957),
      3: MochiElementSpec(MochiElementKind.flowerClay, 68, x: 827, y: 956),
      4: MochiElementSpec(MochiElementKind.flowerOrange, 72, x: 825, y: 943),
    },
  ),
  MochiElementDef(
    key: 'fl8',
    zone: MochiZone.garden,
    x: 760,
    y: 1025,
    levels: {
      1: MochiElementSpec(MochiElementKind.flowerOrange, 58, x: 760, y: 1025),
      2: MochiElementSpec(MochiElementKind.flowerPeach, 62, x: 630, y: 995),
      3: MochiElementSpec(MochiElementKind.flowerPeach, 68, x: 590, y: 1001),
      4: MochiElementSpec(MochiElementKind.flowerYellow, 72, x: 625, y: 996),
    },
  ),
  MochiElementDef(
    key: 'fl9',
    zone: MochiZone.garden,
    x: 622,
    y: 739,
    levels: {
      2: MochiElementSpec(MochiElementKind.flowerPeach, 62, x: 622, y: 739),
    },
  ),
  MochiElementDef(
    key: 'fl10',
    zone: MochiZone.garden,
    x: 801,
    y: 1000,
    levels: {
      2: MochiElementSpec(MochiElementKind.flowerClay, 62, x: 801, y: 1000),
      3: MochiElementSpec(MochiElementKind.flowerClay, 68, x: 785, y: 996),
      4: MochiElementSpec(MochiElementKind.flowerYellow, 72, x: 870, y: 1079),
    },
  ),
  MochiElementDef(
    key: 'fl11',
    zone: MochiZone.garden,
    x: 667,
    y: 1016,
    levels: {
      2: MochiElementSpec(MochiElementKind.flowerCream, 62, x: 667, y: 1016),
      3: MochiElementSpec(MochiElementKind.flowerOrange, 68, x: 655, y: 1031),
      4: MochiElementSpec(MochiElementKind.flowerClay, 72, x: 640, y: 1034),
    },
  ),
  MochiElementDef(
    key: 'fl12',
    zone: MochiZone.garden,
    x: 707,
    y: 1025,
    levels: {
      2: MochiElementSpec(MochiElementKind.flowerYellow, 62, x: 707, y: 1025),
      3: MochiElementSpec(MochiElementKind.flowerYellow, 68, x: 707, y: 1016),
      4: MochiElementSpec(MochiElementKind.flowerOrange, 72, x: 692, y: 965),
    },
  ),
  MochiElementDef(
    key: 'fl13',
    zone: MochiZone.garden,
    x: 880,
    y: 1029,
    levels: {
      2: MochiElementSpec(MochiElementKind.flowerOrange, 62, x: 880, y: 1029),
      3: MochiElementSpec(MochiElementKind.flowerOrange, 68, x: 755, y: 1039),
      4: MochiElementSpec(MochiElementKind.flowerClay, 72, x: 782, y: 1047),
    },
  ),
  MochiElementDef(
    key: 'fl14',
    zone: MochiZone.garden,
    x: 756,
    y: 1039,
    levels: {
      2: MochiElementSpec(MochiElementKind.flowerClay, 62, x: 756, y: 1039),
      3: MochiElementSpec(MochiElementKind.flowerOrange, 68, x: 757, y: 1006),
      4: MochiElementSpec(MochiElementKind.flowerOrange, 72, x: 712, y: 1010),
    },
  ),
  MochiElementDef(
    key: 'fl15',
    zone: MochiZone.garden,
    x: 790,
    y: 1054,
    levels: {
      2: MochiElementSpec(MochiElementKind.flowerOrange, 62, x: 790, y: 1054),
      3: MochiElementSpec(MochiElementKind.flowerClay, 68, x: 817, y: 1034),
      4: MochiElementSpec(MochiElementKind.flowerClay, 72, x: 832, y: 999),
    },
  ),
  MochiElementDef(
    key: 'fl16',
    zone: MochiZone.garden,
    x: 610,
    y: 1045,
    levels: {
      3: MochiElementSpec(MochiElementKind.flowerCream, 68, x: 610, y: 1045),
      4: MochiElementSpec(MochiElementKind.flowerCream, 72, x: 607, y: 1045),
    },
  ),
  MochiElementDef(
    key: 'fl17',
    zone: MochiZone.garden,
    x: 860,
    y: 1061,
    levels: {
      3: MochiElementSpec(MochiElementKind.flowerYellow, 68, x: 860, y: 1061),
      4: MochiElementSpec(MochiElementKind.flowerCream, 72, x: 875, y: 995),
    },
  ),
  MochiElementDef(
    key: 'fl18',
    zone: MochiZone.garden,
    x: 790,
    y: 1073,
    levels: {
      3: MochiElementSpec(MochiElementKind.flowerPeach, 68, x: 790, y: 1073),
      4: MochiElementSpec(MochiElementKind.flowerOrange, 72, x: 840, y: 1048),
    },
  ),
  MochiElementDef(
    key: 'fl19',
    zone: MochiZone.garden,
    x: 695,
    y: 1081,
    levels: {
      3: MochiElementSpec(MochiElementKind.flowerClay, 68, x: 695, y: 1081),
      4: MochiElementSpec(MochiElementKind.flowerClay, 72, x: 675, y: 1062),
    },
  ),
  MochiElementDef(
    key: 'fl20',
    zone: MochiZone.garden,
    x: 640,
    y: 1096,
    levels: {
      3: MochiElementSpec(MochiElementKind.flowerYellow, 68, x: 640, y: 1096),
      4: MochiElementSpec(MochiElementKind.flowerClay, 72, x: 630, y: 1087),
    },
  ),
  MochiElementDef(
    key: 'fl21',
    zone: MochiZone.garden,
    x: 740,
    y: 1100,
    levels: {
      3: MochiElementSpec(MochiElementKind.flowerCream, 68, x: 740, y: 1100),
      4: MochiElementSpec(MochiElementKind.flowerOrange, 72, x: 740, y: 1070),
    },
  ),
  MochiElementDef(
    key: 'fl22',
    zone: MochiZone.garden,
    x: 575,
    y: 1113,
    levels: {
      4: MochiElementSpec(MochiElementKind.flowerCream, 72, x: 575, y: 1113),
    },
  ),
  MochiElementDef(
    key: 'fl23',
    zone: MochiZone.garden,
    x: 705,
    y: 1119,
    levels: {
      4: MochiElementSpec(MochiElementKind.flowerYellow, 72, x: 705, y: 1119),
    },
  ),
  MochiElementDef(
    key: 'crack',
    zone: MochiZone.lake,
    x: 572,
    y: 1040,
    levels: {
      1: MochiElementSpec(MochiElementKind.crackedPatch, 360),
      2: MochiElementSpec(MochiElementKind.crackedPatch, 360),
      3: MochiElementSpec(MochiElementKind.crackedPatch, 360),
      4: MochiElementSpec(MochiElementKind.crackedPatch, 360),
    },
    droughtOnly: true,
    decal: true,
  ),
  MochiElementDef(
    key: 'shrub-a',
    zone: MochiZone.garden,
    x: 250,
    y: 990,
    levels: {
      1: MochiElementSpec(MochiElementKind.shrubDry, 95),
      2: MochiElementSpec(MochiElementKind.shrubDry, 95),
      3: MochiElementSpec(MochiElementKind.shrubDry, 95),
      4: MochiElementSpec(MochiElementKind.shrubDry, 95),
    },
    droughtOnly: true,
  ),
  MochiElementDef(
    key: 'shrub-b',
    zone: MochiZone.garden,
    x: 845,
    y: 830,
    levels: {
      1: MochiElementSpec(MochiElementKind.shrubDry, 80),
      2: MochiElementSpec(MochiElementKind.shrubDry, 80),
      3: MochiElementSpec(MochiElementKind.shrubDry, 80),
      4: MochiElementSpec(MochiElementKind.shrubDry, 80),
    },
    droughtOnly: true,
  ),
  MochiElementDef(
    key: 'shrub-c',
    zone: MochiZone.garden,
    x: 772,
    y: 795,
    levels: {
      2: MochiElementSpec(MochiElementKind.shrubDry, 58),
      3: MochiElementSpec(MochiElementKind.shrubDry, 58),
      4: MochiElementSpec(MochiElementKind.shrubDry, 58),
    },
    droughtOnly: true,
  ),
];

/// Sürükleyici moddaki gösteri — referans sahnelerin sırasıyla: kurak ada
/// canlanır, cennete dönüşür, sonra ihmal edilip yeniden kurur.
const List<MochiWorldState> kMochiDemoStates = [
  (level: 0, health: MochiHealth.drought), // mochi-world-7
  (level: 0, health: MochiHealth.wilting), // mochi-world-6
  (level: 0, health: MochiHealth.thriving), // mochi-world-5
  (level: 1, health: MochiHealth.thriving), // mochi-world-1
  (level: 2, health: MochiHealth.thriving), // mochi-world-2
  (level: 3, health: MochiHealth.thriving), // mochi-world-3
  (level: 4, health: MochiHealth.thriving), // mochi-world-4
  (level: 4, health: MochiHealth.wilting), // mochi-world-8
  (level: 3, health: MochiHealth.wilting), // mochi-world-9
  (level: 2, health: MochiHealth.drought), // mochi-world-10
];

/// Bölge ilerlemesini (0..1) büyüme seviyesine çevirir.
int mochiZoneLevel(double ratio) =>
    (ratio.clamp(0.0, 1.0) * kMochiMaxLevel).round();

/// Her bölge kendi seviyesindeki elementlerini getirir; sağlık, kuru
/// versiyonları seçer. Zemin dokuları önce, sonra arkadan öne sıralı.
List<MochiPlacement> mochiCompose(
  Map<MochiZone, int> levels,
  MochiHealth health,
) {
  final out = <MochiPlacement>[];
  for (final e in kMochiElements) {
    if (e.droughtOnly && health != MochiHealth.drought) continue;
    final level = levels[e.zone] ?? 0;
    final spec = e.levels[level];
    if (spec == null) continue;
    final (kind, faded) = _variant(e, spec.kind, level, health);
    out.add(
      MochiPlacement(
        key: e.key,
        kind: kind,
        x: spec.x ?? e.x,
        y: spec.y ?? e.y,
        width: spec.width,
        flip: e.flip,
        faded: faded,
        decal: e.decal,
      ),
    );
  }
  out.sort((a, b) {
    if (a.decal != b.decal) return a.decal ? -1 : 1;
    return a.y.compareTo(b.y);
  });
  return out;
}

(MochiElementKind, bool) _variant(
  MochiElementDef e,
  MochiElementKind kind,
  int level,
  MochiHealth health,
) {
  if (health == MochiHealth.thriving) return (kind, false);
  if (e.saplingUntil >= level) return (MochiElementKind.saplingWilting, false);
  if (kind.isHealthyTree) {
    return (
      e.bare ? MochiElementKind.treeBare : MochiElementKind.treePale,
      false,
    );
  }
  if (kind.isPond) {
    // Büyük gölette kuraklıkta bile biraz su kalır; küçük gölet tamamen kurur.
    final dried = health == MochiHealth.drought && level <= 1;
    return (
      dried ? MochiElementKind.pondDried : MochiElementKind.pondDrying,
      false,
    );
  }
  if (kind.isSingleFlower) {
    // Solarken çiçeklerin yarısı solar, kuraklıkta hepsi.
    final index = int.tryParse(e.key.replaceFirst('fl', '')) ?? 0;
    if (health == MochiHealth.drought || index.isEven) {
      return (MochiElementKind.flowerWilted, false);
    }
    return (kind, true);
  }
  return (kind, kind.fadesWhenUnwell);
}

/// Adanın taban görseli: sağlıklıda yeşil, solarken kuru çim, kuraklıkta
/// (boş adada) çatlak toprak.
String mochiBaseAsset(int level, MochiHealth health) => switch (health) {
  MochiHealth.thriving => 'assets/images/mochi-worlds.png',
  MochiHealth.wilting when level == 0 => 'assets/images/mochi-world-6.png',
  MochiHealth.drought when level == 0 => 'assets/images/mochi-world-7.png',
  _ => 'assets/images/mochi-world-5.png',
};

/// Gökyüzü: sağlıklıda güneşli, solarken yağmurlu (dolu adada fırtına).
MochiWeather mochiWeather(int level, MochiHealth health) => switch (health) {
  MochiHealth.thriving => MochiWeather.sunny,
  MochiHealth.wilting when level == 0 => MochiWeather.sunny,
  MochiHealth.wilting when level >= kMochiMaxLevel => MochiWeather.storm,
  MochiHealth.drought when level == 0 => MochiWeather.storm,
  _ => MochiWeather.rainy,
};
