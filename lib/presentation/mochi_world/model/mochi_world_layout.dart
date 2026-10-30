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

  /// 3. seviyenin nilüferli göleti; sol kenarındaki girintiye ortadaki
  /// büyük ağacın gövdesi oturur.
  pondGarden('pond_garden', 379 / 640),
  pondDrying('pond_drying', 386 / 640),
  pondDried('pond_dried', 371 / 640),
  crackedPatch('cracked_patch', 405 / 640),

  /// 3. seviyede ön kıyıdan rustik çitin yanından geçip orta ağacın soluna
  /// kıvrılan taşlı kum patika (zemin dokusu; kesik üst kenarı hafifçe
  /// yumuşatılmış, kenarında hafif gölge pişmiş).
  path('path', 515 / 422),

  /// 4. seviyede ön kıyıdan orta ağaca kıvrılan sıcak tonlu taş patika.
  stonePath('stone_path', 550 / 480),
  shrubDry('shrub_dry', 506 / 640),
  mountain('mountain', 445 / 640),

  /// 3. seviyenin dağı: karlı yeşil tepe + önündeki çimenli tepe.
  hillSnow('hill_snow', 450 / 560),
  hillGrass('hill_grass', 316 / 560),

  /// İki katlı şelale + gölet (son seviyede göletin yerine geçer).
  waterfall('waterfall', 641 / 582),
  rainbow('rainbow', 342 / 960),
  bird('bird', 316 / 400),
  fence('fence', 444 / 640),

  /// 3. seviyenin üç direkli, çift raylı rustik çiti.
  fenceRustic('fence_rustic', 365 / 640),
  bench('bench', 537 / 640),
  lantern('lantern', 651 / 360),
  lily('lily', 358 / 640),

  /// Kıyı süsü: papatyalı yeşil çalı / yaprak öbekleri.
  daisyBush1('daisy_bush_1', 275 / 400),
  daisyBush2('daisy_bush_2', 297 / 400),
  daisyBush3('daisy_bush_3', 271 / 400),
  daisyBush4('daisy_bush_4', 267 / 400),
  daisyBush5('daisy_bush_5', 250 / 400),

  /// Solgun (yağmurlu) ada: ağaçlar, gölet, çiçekler ve kıyı bitkileri.
  wiltTreeBare('wilt_tree_bare', 459 / 400),
  wiltTreeRound('wilt_tree_round', 417 / 400),
  wiltTreePale('wilt_tree_pale', 445 / 400),
  wiltTreeSparse('wilt_tree_sparse', 478 / 400),
  wiltTreeYellow('wilt_tree_yellow', 437 / 400),
  wiltPond('wilt_pond', 359 / 640),
  wiltFlowersPink('wilt_flowers_pink', 322 / 400),
  wiltDaisy('wilt_daisy', 333 / 400),
  wiltGroundcover('wilt_groundcover', 273 / 400),
  wiltRosette('wilt_rosette', 247 / 400),
  wiltGrass('wilt_grass', 303 / 400),
  wiltReeds('wilt_reeds', 429 / 400);

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
      isWiltTree ||
      this == treePale ||
      this == treeBare ||
      this == saplingWilting;

  /// Solgun adanın ağaçları.
  bool get isWiltTree => switch (this) {
    wiltTreeBare ||
    wiltTreeRound ||
    wiltTreePale ||
    wiltTreeSparse ||
    wiltTreeYellow => true,
    _ => false,
  };

  /// Solgun adanın çiçek / ot / yaprak bitkileri (rüzgârda hafif sallanır).
  bool get isWiltPlant => switch (this) {
    wiltFlowersPink ||
    wiltDaisy ||
    wiltGroundcover ||
    wiltRosette ||
    wiltGrass ||
    wiltReeds => true,
    _ => false,
  };

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
      this == pondLily ||
      this == pondGarden ||
      this == pondDrying ||
      this == pondDried ||
      this == wiltPond;

  /// Kuru versiyonu olmayan, solunca rengi soluklaşan elementler.
  bool get fadesWhenUnwell => switch (this) {
    flowers ||
    fence ||
    fenceRustic ||
    bench ||
    lantern ||
    mountain ||
    path ||
    stonePath ||
    hillSnow ||
    hillGrass ||
    waterfall ||
    lily => true,
    _ when isDaisyBush => true,
    _ => false,
  };

  bool get isDaisyBush =>
      this == daisyBush1 ||
      this == daisyBush2 ||
      this == daisyBush3 ||
      this == daisyBush4 ||
      this == daisyBush5;
}

/// Bir elementin belirli bir seviyedeki görünümü.
@immutable
final class MochiElementSpec {
  const MochiElementSpec(this.kind, this.width, {this.x, this.y, this.sortY});

  final MochiElementKind kind;

  /// Görsel piksel uzayında genişlik.
  final double width;

  /// Bu seviyeye özel konum (yoksa elementin ana konumu). Çiçekler seviye
  /// atlarken yeni yerlerine kayar.
  final double? x;
  final double? y;

  /// Çizim sırası için taban yerine kullanılır (ör. gölet, girintisine oturan
  /// ağacın arkasında kalsın diye ağacın tabanından biraz yukarıda sayılır).
  final double? sortY;
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
    this.thrivingOnly = false,
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

  /// Yalnızca ada sağlıklıyken görünür (gökkuşağı).
  final bool thrivingOnly;
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
    this.sortY,
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

  /// Çizim sırası anahtarı (yoksa taban [y]).
  final double? sortY;

  /// Çizim sırası: zemin dokuları en altta, gerisi tabanı ekranda aşağıda
  /// olan önde.
  static int compareDrawOrder(MochiPlacement a, MochiPlacement b) {
    if (a.decal != b.decal) return a.decal ? -1 : 1;
    return (a.sortY ?? a.y).compareTo(b.sortY ?? b.y);
  }
}

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
      // Gövde göletin sol girintisine otursun diye biraz aşağıda.
      3: MochiElementSpec(MochiElementKind.tree, 210, x: 420, y: 888),
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
      3: MochiElementSpec(
        MochiElementKind.hillSnow,
        250,
        x: 548,
        y: 722,
        // Yanındaki fidanlarla (y: 712) eşitlenmesin, hep arkada kalsın.
        sortY: 708,
      ),
      4: MochiElementSpec(MochiElementKind.mountain, 561, x: 569, y: 712),
    },
  ),
  MochiElementDef(
    key: 'hill',
    zone: MochiZone.summit,
    x: 660,
    y: 762,
    // Göletin arka kıyısının önünde çizilir.
    levels: {3: MochiElementSpec(MochiElementKind.hillGrass, 224, sortY: 850)},
  ),
  // Tepelerin eteğinde ufak çalılar: tabanları zemine karışsın. Yeşil
  // tepeninkiler, tepe gibi göletin önünde çizilir.
  MochiElementDef(
    key: 'hill-bush-1',
    zone: MochiZone.summit,
    x: 566,
    y: 770,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush3, 52, sortY: 853)},
  ),
  MochiElementDef(
    key: 'hill-bush-2',
    zone: MochiZone.summit,
    x: 612,
    y: 774,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush4, 46, sortY: 854)},
    flip: true,
  ),
  MochiElementDef(
    key: 'hill-bush-3',
    zone: MochiZone.summit,
    x: 664,
    y: 776,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush2, 54, sortY: 855)},
  ),
  MochiElementDef(
    key: 'hill-bush-4',
    zone: MochiZone.summit,
    x: 716,
    y: 772,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush3, 48, sortY: 856)},
    flip: true,
  ),
  MochiElementDef(
    key: 'hill-bush-5',
    zone: MochiZone.summit,
    x: 760,
    y: 766,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush4, 42, sortY: 857)},
  ),
  MochiElementDef(
    key: 'hill-bush-6',
    zone: MochiZone.summit,
    x: 470,
    y: 728,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush4, 40)},
    flip: true,
  ),
  MochiElementDef(
    key: 'hill-bush-7',
    zone: MochiZone.summit,
    x: 540,
    y: 730,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush2, 44)},
  ),
  // Göletin sağ üst kıyısını dolduran irili ufaklı papatyalı çalılar.
  MochiElementDef(
    key: 'pond-bush-1',
    zone: MochiZone.lake,
    x: 706,
    y: 786,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush4, 48)},
  ),
  MochiElementDef(
    key: 'pond-bush-2',
    zone: MochiZone.lake,
    x: 776,
    y: 790,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush2, 62)},
    flip: true,
  ),
  MochiElementDef(
    key: 'pond-bush-3',
    zone: MochiZone.lake,
    x: 846,
    y: 802,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush3, 52)},
  ),
  MochiElementDef(
    key: 'pond-bush-4',
    zone: MochiZone.lake,
    x: 742,
    y: 818,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush1, 92)},
  ),
  MochiElementDef(
    key: 'pond-bush-5',
    zone: MochiZone.lake,
    x: 818,
    y: 830,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush5, 86)},
    flip: true,
  ),
  MochiElementDef(
    key: 'pond-bush-6',
    zone: MochiZone.lake,
    x: 862,
    y: 846,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush3, 44)},
    flip: true,
  ),
  MochiElementDef(
    key: 'pond-bush-7',
    zone: MochiZone.lake,
    x: 704,
    y: 840,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush2, 50)},
    flip: true,
  ),
  MochiElementDef(
    key: 'pond-bush-8',
    zone: MochiZone.lake,
    x: 748,
    y: 852,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush4, 72)},
  ),
  MochiElementDef(
    key: 'pond-bush-9',
    zone: MochiZone.lake,
    x: 796,
    y: 851,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush3, 58)},
    flip: true,
  ),
  MochiElementDef(
    key: 'pond-bush-10',
    zone: MochiZone.lake,
    x: 840,
    y: 862,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush5, 64)},
  ),
  MochiElementDef(
    key: 'pond-bush-11',
    zone: MochiZone.lake,
    x: 874,
    y: 890,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush3, 46)},
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
      // Girintisi ortadaki ağacın (center: 420, 888) gövdesine denk gelir;
      // ağaç göletin önünde çizilir.
      3: MochiElementSpec(
        MochiElementKind.pondGarden,
        360,
        x: 582,
        y: 970,
        sortY: 845,
      ),
      // 4. seviyede gölet, iki katlı şelalenin kendi göletine dönüşür.
    },
  ),
  MochiElementDef(
    key: 'waterfall',
    zone: MochiZone.lake,
    x: 692,
    y: 938,
    // Orta ağacın arkasında kalsın diye erken çizilir.
    levels: {4: MochiElementSpec(MochiElementKind.waterfall, 372, sortY: 830)},
  ),
  // Son seviyede (cennet) dağın tepesinin üstünde, gökyüzünde pastel
  // gökkuşağı. Tabanı en yukarıda olduğu için dağın ve ağaçların arkasında
  // kalır; bacakları bulutlara karışır.
  MochiElementDef(
    key: 'rainbow',
    zone: MochiZone.lake,
    x: 565,
    y: 410,
    levels: {4: MochiElementSpec(MochiElementKind.rainbow, 600)},
    thrivingOnly: true,
  ),
  // Cennette adanın iki yanında birbirine bakan beyaz kuşlar; gökyüzünde
  // oldukları için her şeyin önünde çizilir.
  MochiElementDef(
    key: 'bird-l',
    zone: MochiZone.lake,
    x: 150,
    y: 520,
    levels: {4: MochiElementSpec(MochiElementKind.bird, 100, sortY: 2000)},
    thrivingOnly: true,
  ),
  MochiElementDef(
    key: 'bird-r',
    zone: MochiZone.lake,
    x: 830,
    y: 520,
    levels: {4: MochiElementSpec(MochiElementKind.bird, 88, sortY: 2000)},
    flip: true,
    thrivingOnly: true,
  ),
  MochiElementDef(
    key: 'path',
    zone: MochiZone.garden,
    // Ön kıyıdan başlar, rustik çitin ucundan geçip orta ağacın solundan
    // arkaya dolanır.
    x: 325,
    y: 1090,
    levels: {3: MochiElementSpec(MochiElementKind.path, 240)},
    decal: true,
  ),
  MochiElementDef(
    key: 'stone-path',
    zone: MochiZone.garden,
    // Kıyıdaki fenerle çiçeklerin arasından başlar, bankın önünden orta
    // ağaca kıvrılır.
    x: 420,
    y: 1120,
    levels: {4: MochiElementSpec(MochiElementKind.stonePath, 330)},
    decal: true,
  ),
  MochiElementDef(
    key: 'bench',
    zone: MochiZone.garden,
    x: 250,
    y: 826,
    levels: {4: MochiElementSpec(MochiElementKind.bench, 106)},
  ),
  MochiElementDef(
    key: 'lantern-a',
    zone: MochiZone.garden,
    x: 0,
    y: 0,
    // Çitin başlangıcından hemen önce; arkadaki ağacın önünde çizilir.
    levels: {
      4: MochiElementSpec(
        MochiElementKind.lantern,
        34,
        x: 132,
        y: 890,
        sortY: 920,
      ),
    },
  ),
  MochiElementDef(
    key: 'lantern-b',
    zone: MochiZone.garden,
    x: 0,
    y: 0,
    // Çitin başında, çalıların arasında; çitin önünde çizilir.
    levels: {
      4: MochiElementSpec(
        MochiElementKind.lantern,
        50,
        x: 134,
        y: 944,
        sortY: 990,
      ),
    },
  ),
  MochiElementDef(
    key: 'lantern-c',
    zone: MochiZone.garden,
    x: 0,
    y: 0,
    levels: {
      4: MochiElementSpec(
        MochiElementKind.lantern,
        50,
        x: 432,
        y: 1086,
        sortY: 1300,
      ),
    },
  ),
  // Kıyı boyunca, çitin hemen önünü dolduran iri papatyalı çalılar.
  // Çitin sonundaki fener bunların önünde çizilir (sortY).
  MochiElementDef(
    key: 'shore-daisy-1',
    zone: MochiZone.garden,
    x: 86,
    y: 988,
    levels: {4: MochiElementSpec(MochiElementKind.daisyBush3, 110)},
  ),
  // Lambanın dibinde iri çalı yerine alçak yeşillik + papatyalar.
  MochiElementDef(
    key: 'shore-daisy-2',
    zone: MochiZone.garden,
    x: 112,
    y: 1034,
    levels: {4: MochiElementSpec(MochiElementKind.daisyBush3, 84)},
  ),
  MochiElementDef(
    key: 'shore-daisy-2b',
    zone: MochiZone.garden,
    x: 166,
    y: 1046,
    levels: {4: MochiElementSpec(MochiElementKind.daisyBush4, 72)},
    flip: true,
  ),
  MochiElementDef(
    key: 'shore-daisy-3',
    zone: MochiZone.garden,
    x: 212,
    y: 1056,
    levels: {4: MochiElementSpec(MochiElementKind.daisyBush2, 130)},
    flip: true,
  ),
  MochiElementDef(
    key: 'shore-daisy-4',
    zone: MochiZone.garden,
    x: 294,
    y: 1076,
    levels: {4: MochiElementSpec(MochiElementKind.daisyBush5, 170)},
  ),
  MochiElementDef(
    key: 'shore-daisy-5',
    zone: MochiZone.garden,
    x: 382,
    y: 1092,
    levels: {4: MochiElementSpec(MochiElementKind.daisyBush4, 130)},
    flip: true,
  ),
  MochiElementDef(
    key: 'shore-daisy-6',
    zone: MochiZone.garden,
    x: 468,
    y: 1094,
    levels: {4: MochiElementSpec(MochiElementKind.daisyBush3, 100)},
  ),
  MochiElementDef(
    key: 'fence-rustic',
    zone: MochiZone.garden,
    // Patikanın solunda, ön kıyının çimeninde.
    x: 190,
    y: 1025,
    levels: {3: MochiElementSpec(MochiElementKind.fenceRustic, 200)},
  ),
  // Patikanın sol kenarında ufak papatyalı çalılar.
  MochiElementDef(
    key: 'path-bush-1',
    zone: MochiZone.garden,
    x: 259,
    y: 1040,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush4, 48)},
  ),
  MochiElementDef(
    key: 'path-bush-2',
    zone: MochiZone.garden,
    x: 239,
    y: 1064,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush3, 54)},
    flip: true,
  ),
  MochiElementDef(
    key: 'path-bush-3',
    zone: MochiZone.garden,
    x: 271,
    y: 1086,
    levels: {3: MochiElementSpec(MochiElementKind.daisyBush5, 50)},
  ),
  MochiElementDef(
    key: 'fence-a',
    zone: MochiZone.garden,
    x: 216,
    y: 980,
    levels: {4: MochiElementSpec(MochiElementKind.fence, 160)},
    flip: true,
  ),
  MochiElementDef(
    key: 'fence-b',
    zone: MochiZone.garden,
    // fence-a'nın son direğinden devam eder (aynı hizada).
    x: 346,
    y: 1032,
    levels: {4: MochiElementSpec(MochiElementKind.fence, 160)},
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
    if (e.thrivingOnly && health != MochiHealth.thriving) continue;
    final level = levels[e.zone] ?? 0;
    final spec = e.levels[level];
    if (spec == null) continue;
    final (kind, faded) = _variant(e, spec.kind, level, health);
    // Tek çiçeklerin yerine gelen solgun bitkiler daha geniş, seyrek
    // görsellerdir: aynı yeri doldursunlar diye büyütülür.
    final grow = spec.kind.isSingleFlower && kind.isWiltPlant ? 1.5 : 1.0;
    out.add(
      MochiPlacement(
        key: e.key,
        kind: kind,
        x: spec.x ?? e.x,
        y: spec.y ?? e.y,
        width: spec.width * grow,
        flip: e.flip,
        faded: faded,
        decal: e.decal,
        sortY: spec.sortY,
      ),
    );
  }
  out.sort(MochiPlacement.compareDrawOrder);
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
  final wilting = health == MochiHealth.wilting;
  if (kind.isHealthyTree) {
    return (wilting ? _wiltTree(e) : _droughtTree(e), false);
  }
  // Kuraklıkta yeşil öbekler kurumuş altın çimene / kuru çalıya döner.
  if (!wilting && kind == MochiElementKind.flowers) {
    return (MochiElementKind.wiltGrass, false);
  }
  if (!wilting && kind.isDaisyBush) {
    const nearPond = [MochiElementKind.wiltReeds, MochiElementKind.wiltGrass];
    const elsewhere = [MochiElementKind.wiltGrass, MochiElementKind.shrubDry];
    final pick = e.key.startsWith('pond-bush') ? nearPond : elsewhere;
    return (pick[_stableIndex(e.key) % pick.length], false);
  }
  // Solgun adada nilüferli gölet yağmurlu, solgun göletine döner; kuraklıkta
  // eskisi gibi kurur.
  if (wilting &&
      (kind == MochiElementKind.pondGarden ||
          kind == MochiElementKind.pondLily)) {
    return (MochiElementKind.wiltPond, false);
  }
  if (wilting && kind == MochiElementKind.flowers) {
    return (MochiElementKind.wiltFlowersPink, false);
  }
  if (wilting && kind.isDaisyBush) {
    // Göletin kıyısında saz / kuru ot, diğer yerlerde yaprak / yer örtücü.
    const nearPond = [
      MochiElementKind.wiltReeds,
      MochiElementKind.wiltGrass,
      MochiElementKind.wiltRosette,
    ];
    const elsewhere = [
      MochiElementKind.wiltRosette,
      MochiElementKind.wiltGroundcover,
      MochiElementKind.wiltGrass,
    ];
    final pick = e.key.startsWith('pond-bush') ? nearPond : elsewhere;
    return (pick[_stableIndex(e.key) % pick.length], false);
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
    if (wilting) {
      const wilted = [
        MochiElementKind.wiltDaisy,
        MochiElementKind.wiltFlowersPink,
        MochiElementKind.wiltGroundcover,
      ];
      return (wilted[index % wilted.length], false);
    }
    if (health == MochiHealth.drought || index.isEven) {
      return (MochiElementKind.flowerWilted, false);
    }
    return (kind, true);
  }
  return (kind, kind.fadesWhenUnwell);
}

/// Anahtardan her çalıştırmada aynı kalan sıra (aynı ağaç hep aynı görselde).
int _stableIndex(String key) =>
    key.codeUnits.fold(0, (sum, c) => sum * 31 + c) & 0x7fffffff;

/// Solgun adada ağaç: çıplak işaretliler çıplak; ortadaki büyük ağaç dolgun
/// kalır; diğerleri dört solgun görsel arasında dağılır.
MochiElementKind _wiltTree(MochiElementDef e) {
  if (e.bare) return MochiElementKind.wiltTreeBare;
  if (e.key == 'center') return MochiElementKind.wiltTreeRound;
  const trees = [
    MochiElementKind.wiltTreeRound,
    MochiElementKind.wiltTreePale,
    MochiElementKind.wiltTreeYellow,
    MochiElementKind.wiltTreeSparse,
  ];
  return trees[_stableIndex(e.key) % trees.length];
}

/// Kurak adada ağaç: çıplak işaretliler ve diğerlerinin bir kısmı çıplak
/// dallı; kalanlar seyrek ya da sararmış.
MochiElementKind _droughtTree(MochiElementDef e) {
  if (e.bare) return MochiElementKind.wiltTreeBare;
  if (e.key == 'center') return MochiElementKind.wiltTreeSparse;
  const trees = [
    MochiElementKind.wiltTreeSparse,
    MochiElementKind.wiltTreeBare,
    MochiElementKind.wiltTreeYellow,
  ];
  return trees[_stableIndex(e.key) % trees.length];
}

/// Adanın taban görseli: sağlıklıda yeşil, solarken kuru çim, kuraklıkta
/// (boş adada) çatlak toprak.
String mochiBaseAsset(int level, MochiHealth health) => switch (health) {
  // 3. seviyeden itibaren adanın ortası kumdan çimene döner
  // (asset_sources/mochi/grassify_base.py ile üretildi).
  MochiHealth.thriving when level >= 3 => 'assets/images/mochi-world-green.png',
  MochiHealth.thriving => 'assets/images/mochi-worlds.png',
  MochiHealth.wilting when level == 0 => 'assets/images/mochi-world-6.png',
  MochiHealth.drought when level == 0 => 'assets/images/mochi-world-7.png',
  // Solgun ve kurak ada kasvetli, yağmurlu gökyüzüyle
  // (asset_sources/mochi/rainify_base.py ile üretildi).
  _ => 'assets/images/mochi-world-rain.png',
};

/// Gökyüzü: sağlıklıda güneşli, solarken yağmurlu (dolu adada fırtına).
MochiWeather mochiWeather(int level, MochiHealth health) => switch (health) {
  MochiHealth.thriving => MochiWeather.sunny,
  MochiHealth.wilting when level == 0 => MochiWeather.sunny,
  MochiHealth.wilting when level >= kMochiMaxLevel => MochiWeather.storm,
  _ => MochiWeather.rainy,
};
