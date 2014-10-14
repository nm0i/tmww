server.plugin tests as of 2014-10-04
====================================

call from distribution path with:
$ LC_ALL=C PATH="./bin:${PATH}" build-aux/shtest -E 'DIRCONFIG="tests/confserver"' tests/db.t

IMPORTANT:  testing only server.plugin specific operations
            other tests relates to alts.plugin (and alts.t)

WARNING:    some things in tests like $'\t' are not available dash

NOTE:       running from configs with "s" prefix for reusing test files on
            development folder. Server op may rearrange configs
            to call e.g. char vs schar

NOTE:       these tests do not cover whole possible combinations of queries

char get
--------

regular tests

    $ tmww schar get mage
    2000000
    $ tmww schar get by pcid 150000
    2000000
    $ tmww schar get by char mage
    2000000
    $ tmww schar get by id mage
    Incorrect parameter: get by id mage
    $ tmww schar get accs by char mage
    accid    login   hash                             date                     g  counter  ?  mail     ?  ?  lastip     ?  ?
    2000000  newbie  !Ms^6_$3749dfee1445abfa06907413  2014-09-29 21:42:23.044  M  98       0  a@a.com  -  0  127.0.0.1  !  0
    $ tmww schar get vars by char mage
    TUT_var,1404254543
    FLAGS,256
    TUTORIAL,67108864
    MAGIC_EXPERIENCE,1253338
    QUEST_MAGIC,61440
    PC_DIE_COUNTER,7
    TravelFound,17924
    QUEST_Barbarians,8
    BOSS_POINTS,40
    
    $ tmww schar get db by char mage
    pcid    accid      charname  level    exp/gp         hp/mp              stats            ?    ?      partyid  ?      ?                  location      resp             ?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       inventory                                                                                             ?                                                                                                                                                                skills  vars
    150001  2000000,1  mage      0,109,3  906582,737,43  1011,1064,236,236  1,85,80,99,1,70  3,2  0,0,0  103,0,0  1,1,0  1,601,636,658,768  034-1,70,100  031-3,227,239,0  0,1201,1,0,1,0,0,0,0,0,0,0 0,903,1,0,1,0,0,0,0,0,0,0 0,904,100,0,1,0,0,0,0,0,0,0 0,808,1,0,1,0,0,0,0,0,0,0 0,1202,1,0,1,0,0,0,0,0,0,0 0,881,1,0,1,0,0,0,0,0,0,0 0,1171,1,0,1,0,0,0,0,0,0,0 0,880,1,0,1,0,0,0,0,0,0,0 0,4011,1,0,1,0,0,0,0,0,0,0 0,2202,1,0,1,0,0,0,0,0,0,0 0,879,1,0,1,0,0,0,0,0,0,0 0,758,1,0,1,0,0,0,0,0,0,0 0,579,1,2,1,0,0,0,0,0,0,0 0,735,1,0,1,0,0,0,0,0,0,0 0,743,2,0,1,0,0,0,0,0,0,0 0,718,470,0,1,0,0,0,0,0,0,0 0,613,84,0,1,0,0,0,0,0,0,0 0,611,8,0,1,0,0,0,0,0,0,0 0,585,1,0,1,0,0,0,0,0,0,0 0,601,1,32,1,0,0,0,0,0,0,0 0,658,1,512,1,0,0,0,0,0,0,0 0,518,23,0,1,0,0,0,0,0,0,0 0,4001,8,0,1,0,0,0,0,0,0,0 0,4021,8,0,1,0,0,0,0,0,0,0 0,4025,3,0,1,0,0,0,0,0,0,0 0,4023,9,0,1,0,0,0,0,0,0,0 0,501,5,0,1,0,0,0,0,0,0,0 0,521,1,0,1,0,0,0,0,0,0,0 0,704,192,0,1,0,0,0,0,0,0,0 0,535,1,0,1,0,0,0,0,0,0,0 0,521,1,0,1,0,0,0,0,0,0,0 0,545,1,0,1,0,0,0,0,0,0,0 0,1199,860,0,1,0,0,0,0,0,0,0 0,740,365,0,1,0,0,0,0,0,0,0 0,714,100,0,1,0,0,0,0,0,0,0 0,505,286,0,1,0,0,0,0,0,0,0 0,4026,15,0,1,0,0,0,0,0,0,0 0,4024,3,0,1,0,0,0,0,0,0,0 0,5061,1,0,1,0,0,0,0,0,0,0 0,502,2,0,1,0,0,0,0,0,0,0 0,614,94,0,1,0,0,0,0,0,0,0 0,660,100,0,1,0,0,0,0,0,0,0 0,636,1,256,1,0,0,0,0,0,0,0 0,539,12,0,1,0,0,0,0,0,0,0 0,701,3,0,1,0,0,0,0,0,0,0 0,657,7,0,1,0,0,0,0,0,0,0 0,768,1,1,1,0,0,0,0,0,0,0 0,865,1,0,1,0,0,0,0,0,0,0 0,861,1,0,1,0,0,0,0,0,0,0 0,562,96,0,1,0,0,0,0,0,0,0 0,703,93,0,1,0,0,0,0,0,0,0 0,876,1,64,1,0,0,0,0,0,0,0 0,532,1,4,1,0,0,0,0,0,0,0 0,791,1,0,1,0,0,0,0,0,0,0   1,1 2,1 3,2 45,9 339,1 340,2 341,2 342,2 343,2 344,2 345,2 346,2 350,9 352,9 353,9 354,262153 355,1   TUT_var,1404254543 FLAGS,256 TUTORIAL,67108864 MAGIC_EXPERIENCE,1253338 QUEST_MAGIC,61440 PC_DIE_COUNTER,7 TravelFound,17924 QUEST_Barbarians,8 BOSS_POINTS,40 
    $ tmww schar get q1 by char mage
    lvl  gp  sgp  lastip     g  accid    charname  party      accid    charname
    109  43       127.0.0.1  M  2000000  mage      mageparty  2000000  mage
    $ tmww schar get skills by char mage
    Emote (#1): 1
    Trade (#2): 1
    Party (#3): 2
    Mallard's Eye (#45): 9
    Skill Pool (#339): 1
    Magic (#340): 2
    Life Magic (#341): 2
    War Magic (#342): 2
    Transmutation Magic (#343): 2
    Nature Magic (#344): 2
    Astral Magic (#345): 2
    Dark Magic (#346): 2
    Brawling (#350): 9
    Speed (#352): 9
    Poison Resistance (#353): 9
    Astral Soul (#354): 262153
    Raging (#355): 1
    $ tmww schar get inventory by char mage
    ID    N    Name
    658   1    WarlordPlate
    791   1    YetiSkinShirt
    880   1    LazuriteRobe
    1202  1    CottonShirt
    5061  1    BlackSorcererRobeBlack
    735   1    CottonBoots
    876   1    WarlordBoots
    505   286  MaggotSlime
    518   23   BugLeg
    611   8    WhiteFur
    613   84   HardSpike
    614   94   PinkAntenna
    660   100  CottonCloth
    701   3    PileOfAsh
    703   93   SulphurPowder
    704   192  IronPowder
    718   470  SilkCocoon
    740   365  Root
    861   1    WhiteBellTuber
    4001  8    Coal
    4021  8    YellowPresentBox
    4023  9    AnimalBones
    4024  3    FrozenYetiTear
    4025  3    YetiClaw
    4026  15   IceCube
    532   1    LeatherGloves
    636   1    WarlordHelmet
    2202  1    DarkBlueWizardHat
    768   1    TerraniteLegs
    881   1    RaggedShorts
    585   1    ScarabArmlet
    601   1    SteelShield
    865   1    Grimoire
    879   1    HeartOfIsis
    4011  1    SapphireRing
    501   5    CactusDrink
    502   2    CactusPotion
    535   1    RedApple
    539   12   Beer
    562   96   ChickenLeg
    657   7    Orange
    714   100  SnakeEgg
    743   2    Acorn
    808   1    HitchhikersTowel
    521   1    Dagger
    545   1    ForestBow
    579   1    RockKnife
    758   1    WoodenStaff
    1171  1    Wand
    903   1    SlingShot
    904   100  SlingBullet
    1199  860  Arrow
    1201  1    Knife

checking if empty fields generated with different methods do not shift columns

    $ tmww schar get sgp by char mage
    sgp  accid    charname
         2000000  mage
    $ tmww schar get PerCharVar by char mage
    PerCharVar  accid    charname
                2000000  mage
    $ tmww schar get fstats by char mage
    fstats           accid    charname
    1,85,80,99,1,70  2000000  mage

options

    $ tmww schar -nca get q1 by char mage
       127.0.0.1  M  2000000

fallpits
FIXME

    $ tmww schar get DoesNotExist

char show
---------

regular tests

    $ tmww schar show mage
    2000000 farmer
    2000000 mage
    2000000 mmadmin
    $ tmww schar show chars by char mage
    farmer
    mage
    mmadmin
    $ tmww schar show ids by id 2000000
    2000000 farmer
    2000000 mage
    2000000 mmadmin
    $ tmww schar show pcids by pcid 150000
    150000 2000000 farmer
    150001 2000000 mage
    150009 2000000 mmadmin
    $ tmww schar show vars by char user3c2
    2000003	#BankAccount,29 
    $ tmww schar show db by char mage
    pcid    accid      charname  level    exp/gp              hp/mp              stats             ?       ?      partyid  ?       ?                   location      resp             ?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       inventory                                                                                             ?                                                                                                                                                                skills  vars
    150000  2000000,0  farmer    0,100,1  99041,19029,999982  235,811,176,218    2,99,60,99,90,49  9,0     0,0,0  101,0,0  6,1,0   11,0,1217,5055,768  007-1,85,78   042-2,26,26,0    0,1201,1,0,1,0,0,0,0,0,0,0 0,903,1,0,1,0,0,0,0,0,0,0 0,904,100,0,1,0,0,0,0,0,0,0 0,808,1,0,1,0,0,0,0,0,0,0 0,1202,1,0,1,0,0,0,0,0,0,0 0,881,1,0,1,0,0,0,0,0,0,0 0,1217,1,256,1,0,0,0,0,0,0,0 0,4012,1,128,1,0,0,0,0,0,0,0 0,5055,1,512,1,0,0,0,0,0,0,0 0,768,1,1,1,0,0,0,0,0,0,0 0,735,1,0,1,0,0,0,0,0,0,0 0,1199,4197,32768,1,0,0,0,0,0,0,0 0,567,100,0,1,0,0,0,0,0,0,0 0,568,100,0,1,0,0,0,0,0,0,0 0,562,50,0,1,0,0,0,0,0,0,0 0,541,132,0,1,0,0,0,0,0,0,0 0,879,1,8,1,0,0,0,0,0,0,0 0,878,1,34,1,0,0,0,0,0,0,0 0,533,3,0,1,0,0,0,0,0,0,0 0,4001,3,0,1,0,0,0,0,0,0,0 0,862,98,0,1,0,0,0,0,0,0,0 0,505,7,0,1,0,0,0,0,0,0,0 0,521,1,0,1,0,0,0,0,0,0,0 0,540,18,0,1,0,0,0,0,0,0,0 0,4002,1,0,1,0,0,0,0,0,0,0 0,526,1,0,1,0,0,0,0,0,0,0 0,537,3,0,1,0,0,0,0,0,0,0 0,518,2,0,1,0,0,0,0,0,0,0 0,611,3,0,1,0,0,0,0,0,0,0 0,501,2,0,1,0,0,0,0,0,0,0 0,521,1,0,1,0,0,0,0,0,0,0 0,521,1,0,1,0,0,0,0,0,0,0 0,528,1,0,1,0,0,0,0,0,0,0 0,535,4,0,1,0,0,0,0,0,0,0 0,528,1,0,1,0,0,0,0,0,0,0 0,525,1,0,1,0,0,0,0,0,0,0 0,4003,1,0,1,0,0,0,0,0,0,0 0,1251,5,0,1,0,0,0,0,0,0,0 0,718,2,0,1,0,0,0,0,0,0,0 0,681,1,0,1,0,0,0,0,0,0,0 0,680,3,0,1,0,0,0,0,0,0,0 0,824,37,0,1,0,0,0,0,0,0,0 0,822,111,0,1,0,0,0,0,0,0,0 0,4024,37,0,1,0,0,0,0,0,0,0 0,704,181,0,1,0,0,0,0,0,0,0 0,1248,1,0,1,0,0,0,0,0,0,0 0,683,4,0,1,0,0,0,0,0,0,0 0,1252,3,0,1,0,0,0,0,0,0,0 0,682,1,0,1,0,0,0,0,0,0,0 0,565,3,0,1,0,0,0,0,0,0,0 0,743,1,0,1,0,0,0,0,0,0,0 0,1202,1,0,1,0,0,0,0,0,0,0 0,1201,1,0,1,0,0,0,0,0,0,0                         3,2 339,1 340,2 341,2 342,2 343,2 344,2 345,2 346,2 352,262153                                        TUT_var,1404076785 FLAGS,256 QUEST_MAGIC,61440 TravelFound,516 MAGIC_EXPERIENCE,8000 QUEST_NorthTulimshar,327680 
    150001  2000000,1  mage      0,109,3  906582,737,43       1011,1064,236,236  1,85,80,99,1,70   3,2     0,0,0  103,0,0  1,1,0   1,601,636,658,768   034-1,70,100  031-3,227,239,0  0,1201,1,0,1,0,0,0,0,0,0,0 0,903,1,0,1,0,0,0,0,0,0,0 0,904,100,0,1,0,0,0,0,0,0,0 0,808,1,0,1,0,0,0,0,0,0,0 0,1202,1,0,1,0,0,0,0,0,0,0 0,881,1,0,1,0,0,0,0,0,0,0 0,1171,1,0,1,0,0,0,0,0,0,0 0,880,1,0,1,0,0,0,0,0,0,0 0,4011,1,0,1,0,0,0,0,0,0,0 0,2202,1,0,1,0,0,0,0,0,0,0 0,879,1,0,1,0,0,0,0,0,0,0 0,758,1,0,1,0,0,0,0,0,0,0 0,579,1,2,1,0,0,0,0,0,0,0 0,735,1,0,1,0,0,0,0,0,0,0 0,743,2,0,1,0,0,0,0,0,0,0 0,718,470,0,1,0,0,0,0,0,0,0 0,613,84,0,1,0,0,0,0,0,0,0 0,611,8,0,1,0,0,0,0,0,0,0 0,585,1,0,1,0,0,0,0,0,0,0 0,601,1,32,1,0,0,0,0,0,0,0 0,658,1,512,1,0,0,0,0,0,0,0 0,518,23,0,1,0,0,0,0,0,0,0 0,4001,8,0,1,0,0,0,0,0,0,0 0,4021,8,0,1,0,0,0,0,0,0,0 0,4025,3,0,1,0,0,0,0,0,0,0 0,4023,9,0,1,0,0,0,0,0,0,0 0,501,5,0,1,0,0,0,0,0,0,0 0,521,1,0,1,0,0,0,0,0,0,0 0,704,192,0,1,0,0,0,0,0,0,0 0,535,1,0,1,0,0,0,0,0,0,0 0,521,1,0,1,0,0,0,0,0,0,0 0,545,1,0,1,0,0,0,0,0,0,0 0,1199,860,0,1,0,0,0,0,0,0,0 0,740,365,0,1,0,0,0,0,0,0,0 0,714,100,0,1,0,0,0,0,0,0,0 0,505,286,0,1,0,0,0,0,0,0,0 0,4026,15,0,1,0,0,0,0,0,0,0 0,4024,3,0,1,0,0,0,0,0,0,0 0,5061,1,0,1,0,0,0,0,0,0,0 0,502,2,0,1,0,0,0,0,0,0,0 0,614,94,0,1,0,0,0,0,0,0,0 0,660,100,0,1,0,0,0,0,0,0,0 0,636,1,256,1,0,0,0,0,0,0,0 0,539,12,0,1,0,0,0,0,0,0,0 0,701,3,0,1,0,0,0,0,0,0,0 0,657,7,0,1,0,0,0,0,0,0,0 0,768,1,1,1,0,0,0,0,0,0,0 0,865,1,0,1,0,0,0,0,0,0,0 0,861,1,0,1,0,0,0,0,0,0,0 0,562,96,0,1,0,0,0,0,0,0,0 0,703,93,0,1,0,0,0,0,0,0,0 0,876,1,64,1,0,0,0,0,0,0,0 0,532,1,4,1,0,0,0,0,0,0,0 0,791,1,0,1,0,0,0,0,0,0,0   1,1 2,1 3,2 45,9 339,1 340,2 341,2 342,2 343,2 344,2 345,2 346,2 350,9 352,9 353,9 354,262153 355,1   TUT_var,1404254543 FLAGS,256 TUTORIAL,67108864 MAGIC_EXPERIENCE,1253338 QUEST_MAGIC,61440 PC_DIE_COUNTER,7 TravelFound,17924 QUEST_Barbarians,8 BOSS_POINTS,40 
    150009  2000000,2  mmadmin   0,99,1   0,0,999966          535,535,110,110    9,9,1,1,9,1       1544,0  0,0,0  0,0,0    12,3,0  0,0,0,0,0           007-1,85,77   042-2,26,26,0    0,1201,1,0,1,0,0,0,0,0,0,0 0,903,1,0,1,0,0,0,0,0,0,0 0,904,100,0,1,0,0,0,0,0,0,0 0,808,1,0,1,0,0,0,0,0,0,0 0,1202,1,0,1,0,0,0,0,0,0,0 0,881,1,0,1,0,0,0,0,0,0,0 0,903,1,0,1,0,0,0,0,0,0,0 0,862,1,0,1,0,0,0,0,0,0,0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     2,1 3,2                                                                                               TUT_var,1411769114 FLAGS,256 QUEST_NorthTulimshar,65536 
    $ tmww schar show accs by char mage
    accid    login   hash                             date                     g  counter  ?  mail     ?  ?  lastip     ?  ?
    2000000  newbie  !Ms^6_$3749dfee1445abfa06907413  2014-09-29 21:42:23.044  M  98       0  a@a.com  -  0  127.0.0.1  !  0
    $ tmww schar show parties by char mage
    parties  accid    charname
             2000000  farmer
             2000000  mage
             2000000  mmadmin
    $ tmww schar show storage by char mage
    ID   N   Name
    753  13  BatWing
    754  11  BatTeeth
    743  16  Acorn
    $ tmww schar show "#nothing" AgainNothing by char mage
    #nothing  AgainNothing  accid    charname
                            2000000  farmer
                            2000000  mage
                            2000000  mmadmin
    $ tmww schar -a show "#nothing" AgainNothing by char mage
    #nothing  accid
              2000000

sorts, options

    $ tmww schar -nca get q1 by char mage
       127.0.0.1  M  2000000
    $ tmww schar -cr show lvl PC_DIE_COUNTER by char mage | sort -k 1,1 | cat
    100	 	2000000	farmer
    109	7	2000000	mage
    99	 	2000000	mmadmin

other

    $ tmww schar fuzzy user1c
    user1c1
    user2c1
    user3c1
    user1c3
    user1c2
    user3c2

party
-----

    $ tmww sparty dig par
    2000000 farmer                   -- party2
    2000000 mage                     -- mageparty
    2000003 user3c2                  -- mageparty
    2000003 user3c2                  -- mageparty
    $ tmww sparty get mage
    mageparty
    $ tmww sparty show pcids by char mage
    150001 2000000 mage
    150008 2000003 user3c2
    150008 2000003 user3c2

player get
----------

    $ tmww splayer get by pcid 150000

player show
-----------

    $ tmww splayer show pcids by char mage

char summary
------------

    $ tmww schar summary gp by char mage
    1999991
    $ tmww schar summary bp by char mage
    40
    $ tmww schar summary exp by char mage
    406240051
    $ tmww schar summary items by char mage
    ID    N     Name
    658   1     WarlordPlate
    791   1     YetiSkinShirt
    880   1     LazuriteRobe
    1202  4     CottonShirt
    5055  1     RedSorcererRobeBlack
    5061  1     BlackSorcererRobeBlack
    528   2     Boots
    735   2     CottonBoots
    876   1     WarlordBoots
    505   293   MaggotSlime
    518   25    BugLeg
    526   1     CoinBag
    537   3     TreasureKey
    540   18    EmptyBottle
    611   11    WhiteFur
    613   84    HardSpike
    614   94    PinkAntenna
    660   100   CottonCloth
    680   3     MauveHerb
    681   1     CobaltHerb
    682   1     GambogeHerb
    683   4     AlizarinHerb
    701   3     PileOfAsh
    703   93    SulphurPowder
    704   373   IronPowder
    718   472   SilkCocoon
    740   365   Root
    753   13    BatWing
    754   11    BatTeeth
    822   111   SapphirePowder
    824   37    AmethystPowder
    861   1     WhiteBellTuber
    862   99    IcedWater
    4001  11    Coal
    4002  1     Diamond
    4003  1     Ruby
    4021  8     YellowPresentBox
    4023  9     AnimalBones
    4024  40    FrozenYetiTear
    4025  3     YetiClaw
    4026  15    IceCube
    532   1     LeatherGloves
    525   1     MinersHat
    636   1     WarlordHelmet
    1217  1     CatEars
    2202  1     DarkBlueWizardHat
    768   2     TerraniteLegs
    881   3     RaggedShorts
    585   1     ScarabArmlet
    601   1     SteelShield
    865   1     Grimoire
    879   2     HeartOfIsis
    4011  1     SapphireRing
    4012  1     TopazRing
    501   7     CactusDrink
    502   2     CactusPotion
    533   3     RoastedMaggot
    535   5     RedApple
    539   12    Beer
    541   132   BottleOfWater
    562   146   ChickenLeg
    565   3     PinkPetal
    567   100   IronPotion
    568   100   ConcentrationPotion
    657   7     Orange
    714   100   SnakeEgg
    743   19    Acorn
    808   3     HitchhikersTowel
    1248  1     Blueberries
    1251  5     Plum
    1252  3     Cherry
    521   5     Dagger
    545   1     ForestBow
    579   1     RockKnife
    758   1     WoodenStaff
    1171  1     Wand
    878   1     BansheeBow
    903   4     SlingShot
    904   300   SlingBullet
    1199  5057  Arrow
    1201  4     Knife

player summary
--------------

    $ tmww splayer summary gp by char mage
    1999991
    $ tmww splayer summary gp by player p1
    No such player: p1
    $ tmww splayer summary gp by id 2000001
    150
    $ tmww splayer summary gp by pcid 150000
    1999991
    $ tmww splayer summary bp by char mage
    40
    $ tmww splayer summary exp by char mage
    406240051
    $ tmww splayer summary items by char mage
    ID    N     Name
    658   1     WarlordPlate
    791   1     YetiSkinShirt
    880   1     LazuriteRobe
    1202  4     CottonShirt
    5055  1     RedSorcererRobeBlack
    5061  1     BlackSorcererRobeBlack
    528   2     Boots
    735   2     CottonBoots
    876   1     WarlordBoots
    505   293   MaggotSlime
    518   25    BugLeg
    526   1     CoinBag
    537   3     TreasureKey
    540   18    EmptyBottle
    611   11    WhiteFur
    613   84    HardSpike
    614   94    PinkAntenna
    660   100   CottonCloth
    680   3     MauveHerb
    681   1     CobaltHerb
    682   1     GambogeHerb
    683   4     AlizarinHerb
    701   3     PileOfAsh
    703   93    SulphurPowder
    704   373   IronPowder
    718   472   SilkCocoon
    740   365   Root
    753   13    BatWing
    754   11    BatTeeth
    822   111   SapphirePowder
    824   37    AmethystPowder
    861   1     WhiteBellTuber
    862   99    IcedWater
    4001  11    Coal
    4002  1     Diamond
    4003  1     Ruby
    4021  8     YellowPresentBox
    4023  9     AnimalBones
    4024  40    FrozenYetiTear
    4025  3     YetiClaw
    4026  15    IceCube
    532   1     LeatherGloves
    525   1     MinersHat
    636   1     WarlordHelmet
    1217  1     CatEars
    2202  1     DarkBlueWizardHat
    768   2     TerraniteLegs
    881   3     RaggedShorts
    585   1     ScarabArmlet
    601   1     SteelShield
    865   1     Grimoire
    879   2     HeartOfIsis
    4011  1     SapphireRing
    4012  1     TopazRing
    501   7     CactusDrink
    502   2     CactusPotion
    533   3     RoastedMaggot
    535   5     RedApple
    539   12    Beer
    541   132   BottleOfWater
    562   146   ChickenLeg
    565   3     PinkPetal
    567   100   IronPotion
    568   100   ConcentrationPotion
    657   7     Orange
    714   100   SnakeEgg
    743   19    Acorn
    808   3     HitchhikersTowel
    1248  1     Blueberries
    1251  5     Plum
    1252  3     Cherry
    521   5     Dagger
    545   1     ForestBow
    579   1     RockKnife
    758   1     WoodenStaff
    1171  1     Wand
    878   1     BansheeBow
    903   4     SlingShot
    904   300   SlingBullet
    1199  5057  Arrow
    1201  4     Knife

select
------

    $ tmww select -nic by names RaggedShorts
    inventory of "farmer"; 2000000: farmer, mage, mmadmin
    match: RaggedShorts (881)
    inventory of "mage"; 2000000: farmer, mage, mmadmin
    match: RaggedShorts (881)
    inventory of "user1c1"; 2000001: user1c1, user1c3, user1c2
    match: RaggedShorts (881)
    inventory of "user2c1"; 2000002: user2c1
    match: RaggedShorts (881)
    inventory of "user1c3"; 2000001: user1c1, user1c3, user1c2
    match: RaggedShorts (881)
    inventory of "user1c2"; 2000001: user1c1, user1c3, user1c2
    match: RaggedShorts (881)
    inventory of "user3c2"; 2000003: user3c1, user3c2
    match: RaggedShorts (881)
    inventory of "mmadmin"; 2000000: farmer, mage, mmadmin
    match: RaggedShorts (881)
    $ tmww select -nisc by re shorts
    inventory of "farmer"; 2000000: farmer, mage, mmadmin; match: RaggedShorts (881)
    inventory of "mage"; 2000000: farmer, mage, mmadmin; match: RaggedShorts (881)
    inventory of "user1c1"; 2000001: user1c1, user1c3, user1c2; match: RaggedShorts (881)
    inventory of "user2c1"; 2000002: user2c1; match: RaggedShorts (881)
    inventory of "user1c3"; 2000001: user1c1, user1c3, user1c2; match: RaggedShorts (881)
    inventory of "user1c2"; 2000001: user1c1, user1c3, user1c2; match: RaggedShorts (881)
    inventory of "user3c2"; 2000003: user3c1, user3c2; match: RaggedShorts (881)
    inventory of "mmadmin"; 2000000: farmer, mage, mmadmin; match: RaggedShorts (881)
    $ tmww select -nic by itemsets 'rares*' 'value*'
    inventory of "mage"; 2000000: farmer, mage, mmadmin
    match: ScarabArmlet (585)
    inventory of "user3c1"; 2000003: user3c1, user3c2
    match: Eyepatch (621)
    inventory of "user1c3"; 2000001: user1c1, user1c3, user1c2
    match: PaperBag (1218)

