ItemDB tests as of 2014-10-04
=============================

call from distribution path with:
$ LC_ALL=C PATH="./bin:${PATH}" build-aux/shtest -E 'DIRCONFIG="tests/confserver"' tests/db.t

item get
--------

    $ tmww item get GreenApple
    719
    $ tmww item get id by name RedApple
    535
    $ tmww item get by id 719
    GreenApple
    $ tmww item get name by id 719
    GreenApple
    $ tmww item get db by name GreenApple
    ID   Name        Label        Type  Price  Sell  Weight  ATK  DEF  Range  Mbonus  Slot  Gender  Loc  wLV  eLV  View  UseScript
    719  GreenApple  Green Apple  0     20     5     5       0    0    0      0       0     2       0    0    0    0     {itemheal 45  0;}  {}
    $ tmww item get db by id 719
    ID   Name        Label        Type  Price  Sell  Weight  ATK  DEF  Range  Mbonus  Slot  Gender  Loc  wLV  eLV  View  UseScript
    719  GreenApple  Green Apple  0     20     5     5       0    0    0      0       0     2       0    0    0    0     {itemheal 45  0;}  {}
    $ tmww item -crf 2-5 get db by id 719 | hd
    00000000  47 72 65 65 6e 41 70 70  6c 65 09 47 72 65 65 6e  |GreenApple.Green|
    00000010  20 41 70 70 6c 65 09 30  09 32 30 0a              | Apple.0.20.|
    0000001c

faulty cut expression

    $ tmww item -f 2-0 get db by id 719
    ? 0
    cut: invalid decreasing range
    Try `cut --help' for more information.

item show
---------

    $ tmww item show db by ids 535 719
    ID   Name        Label        Type  Price  Sell  Weight  ATK  DEF  Range  Mbonus  Slot  Gender  Loc  wLV  eLV  View  UseScript
    535  RedApple    Red Apple    0     25     6     5       0    0    0      0       0     2       0    0    0    0     {itemheal 50  0;}  {}
    719  GreenApple  Green Apple  0     20     5     5       0    0    0      0       0     2       0    0    0    0     {itemheal 45  0;}  {}
    $ tmww item show db by names GreenApple RedApple
    ID   Name        Label        Type  Price  Sell  Weight  ATK  DEF  Range  Mbonus  Slot  Gender  Loc  wLV  eLV  View  UseScript
    535  RedApple    Red Apple    0     25     6     5       0    0    0      0       0     2       0    0    0    0     {itemheal 50  0;}  {}
    719  GreenApple  Green Apple  0     20     5     5       0    0    0      0       0     2       0    0    0    0     {itemheal 45  0;}  {}
    $ tmww item show by re apple
    ID    Name                  Label                   Type  Price  Sell  Weight  ATK  DEF  Range  Mbonus  Slot  Gender  Loc  wLV  eLV  View  UseScript
    535   RedApple              Red Apple               0     25     6     5       0    0    0      0       0     2       0    0    0    0     {itemheal 50    0;}  {}
    719   GreenApple            Green Apple             0     20     5     5       0    0    0      0       0     2       0    0    0    0     {itemheal 45    0;}  {}
    739   AppleCake             Apple Cake              0     600    150   10      0    0    0      0       0     2       0    0    0    0     {itemheal 12    0;}  {}
    787   Snapple               Snapple                 0     110    55    5       0    0    0      0       0     2       0    0    0    0     {itemheal 70    0;}  {}
    1229  CaramelApple          Caramel Apple           0     500    75    5       0    0    0      0       0     2       0    0    0    0     {itemheal 1000  0;}  {}
    1253  GoldenDeliciousApple  Golden Delicious Apple  0     1000   500   30      0    0    0      0       0     2       0    0    0    0     {itemheal 200   0;}  {}
    $ tmww item show db by re apple
    ID    Name                  Label                   Type  Price  Sell  Weight  ATK  DEF  Range  Mbonus  Slot  Gender  Loc  wLV  eLV  View  UseScript
    535   RedApple              Red Apple               0     25     6     5       0    0    0      0       0     2       0    0    0    0     {itemheal 50    0;}  {}
    719   GreenApple            Green Apple             0     20     5     5       0    0    0      0       0     2       0    0    0    0     {itemheal 45    0;}  {}
    739   AppleCake             Apple Cake              0     600    150   10      0    0    0      0       0     2       0    0    0    0     {itemheal 12    0;}  {}
    787   Snapple               Snapple                 0     110    55    5       0    0    0      0       0     2       0    0    0    0     {itemheal 70    0;}  {}
    1229  CaramelApple          Caramel Apple           0     500    75    5       0    0    0      0       0     2       0    0    0    0     {itemheal 1000  0;}  {}
    1253  GoldenDeliciousApple  Golden Delicious Apple  0     1000   500   30      0    0    0      0       0     2       0    0    0    0     {itemheal 200   0;}  {}

tests failed with typename in fields alias might happen if const.txt will be changed

    $ tmww item show i1 by re apple
    Type  Typename  Weight  ATK  DEF  Mbonus  UseScript              ID    Name
    0               5       0    0    0       {itemheal 50,0;},{}    535   RedApple
    0               5       0    0    0       {itemheal 45,0;},{}    719   GreenApple
    0               10      0    0    0       {itemheal 12,0;},{}    739   AppleCake
    0               5       0    0    0       {itemheal 70,0;},{}    787   Snapple
    0               5       0    0    0       {itemheal 1000,0;},{}  1229  CaramelApple
    0               30      0    0    0       {itemheal 200,0;},{}   1253  GoldenDeliciousApple
    $ tmww item show names by re apple
    RedApple
    GreenApple
    AppleCake
    Snapple
    CaramelApple
    GoldenDeliciousApple
    $ tmww item show ids by re apple
    535   RedApple
    719   GreenApple
    739   AppleCake
    787   Snapple
    1229  CaramelApple
    1253  GoldenDeliciousApple

custom fields

    $ tmww item show atk def by names GreenApple BottleOfWater
    ATK  DEF  ID   Name
    0    0    541  BottleOfWater
    0    0    719  GreenApple
    $ tmww item -n show atk def by names GreenApple BottleOfWater
    ATK  DEF
    0    0
    0    0
    $ tmww item -rn show atk def by names GreenApple BottleOfWater
    ATK	DEF	
    0	0
    0	0
    $ tmww item -c show fname by re terranite
    chest_item_db.txt    767  TerraniteChestArmor
    generic_item_db.txt  763  TerraniteOre
    head_item_db.txt     766  TerraniteHelmet
    leg_item_db.txt      768  TerraniteLegs
    weapon_item_db.txt   762  TerraniteArrow

priority of id.itemset vs names.itemset (testids.names.itemset should contain less elements)

    $ tmww item show names by itemset testids
    RedApple
    GreenApple
    GoldenDeliciousApple
    $ tmww item show ids by itemset testnames
    621
    585

item mobs
---------

    $ tmww item mobs by ids 719 541
    1041,   Snail
    1083,   HuntsmanSpider
    1093,   WhiteSlime
    1005,   GreenSlime
    1033,   SeaSlime
    1028,   Mouboo
    1109,   AngrySeaSlime
    1115,   SeaSlimeMother
    $ tmww item mobs by names GreenApple BottleOfWater
    1041,   Snail
    1083,   HuntsmanSpider
    1093,   WhiteSlime
    1005,   GreenSlime
    1033,   SeaSlime
    1028,   Mouboo
    1109,   AngrySeaSlime
    1115,   SeaSlimeMother
    $ tmww item mobs by re bottle
    1095,   WhiteBell
    1093,   WhiteSlime
    1033,   SeaSlime
    1004,   RedScorpion
    1028,   Mouboo
    1109,   AngrySeaSlime
    1115,   SeaSlimeMother
    1013,   EvilMushroom
    1014,   PinkFlower
    1130,   Moonshroom

mob get
-------

    $ tmww mob get Snake
    1010
    $ tmww mob get id by name Snake
    1010
    $ tmww mob get name by id 1010
    Snake
    $ tmww mob show names by re snake
    CaveSnake
    Snake
    MountainSnake
    GrassSnake
    SoulSnake
    $ tmww mob show ids by re snake
    1021  CaveSnake
    1010  Snake
    1026  MountainSnake
    1034  GrassSnake
    1096  SoulSnake
    $ tmww mob show db by names Snake CaveSnake
    ID    Name       Jname      LV   HP   SP  EXP  JEXP  Range1  ATK1  ATK2  DEF  MDEF  STR  AGI  VIT  INT  DEX  LUK  Range2  Range3  Scale  Race  Element  Mode  Speed  Adelay  Amotion  Dmotion  D1id  D1p   D2id  D2p  D3id  D3p  D4id  D4p  D5id  D5p  D6id  D6p  D7id  D7p  D8id  D8p  Item1  Item2  MEXP  ExpPer  MVP1id  MVP1per  MVP2id  MVP2per  MVP3id  MVP3per  mutationcount  mutationstrength
    1021  CaveSnake  CaveSnake  30   800  0   0    13    1       20    15    1    5     10   1    1    0    5    20   1       1       1      3     20       129   800    1872    672      480      612   1000  610   40   713   500  717   400  717   400  641   20   0     0    0     0    0      0      0     0       0       0        0       0        0       0        3              50
    1010  Snake      Snake      115  850  0   0    56    1       75    90    4    6     20   11   10   10   35   10   1       1       1      0     20       133   900    1300    672      480      641   150   0     0    714   400  714   400  710   500  0     0    0     0    0     0    0      0      0     0       0       0        0       0        0       0        2              30
    $ tmww mob show m1 by names Snake CaveSnake
    LV   HP   SP  Speed  STR  AGI  VIT  INT  DEX  LUK  ID    Name
    30   800  0   800    10   1    1    0    5    20   1021  CaveSnake
    115  850  0   900    20   11   10   10   35   10   1010  Snake
    $ tmww mob show drops by ids 1010 1021
    D1id  D2id  D3id  D4id  D5id  D6id  D7id  D8id  ID    Name
    612   610   713   717   717   641   0     0     1021  CaveSnake
    641   0     714   714   710   0     0     0     1010  Snake
    $ tmww mob show drops by re snake
    D1id  D2id  D3id  D4id  D5id  D6id  D7id  D8id  ID    Name
    612   610   713   717   717   641   0     0     1021  CaveSnake
    641   0     714   714   710   0     0     0     1010  Snake
    532   641   715   715   711   0     0     0     1026  MountainSnake
    716   716   712   676   660   641   0     0     1034  GrassSnake
    0     0     0     0     0     0     0     0     1096  SoulSnake
    $ tmww mob drops by name JackO
    3.00%    617   PirateHat
    4.00%    622   Bandana
    4.00%    624   VNeckSweater
    4.00%    620   Circlet
    3.00%    615   PumpkinHelmet
    4.00%    1203  RangerHat
    100.00%  1198  Soul
    6.00%    616   AxeHat
    $ tmww mob drops by id 1010
    1.50%  641  SnakeSkin
    4.00%  714  SnakeEgg
    4.00%  714  SnakeEgg
    5.00%  710  SnakeTongue

