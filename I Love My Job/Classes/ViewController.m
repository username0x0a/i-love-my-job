//
//  ViewController.m
//  I Love My Job
//
//  Created by Michi on 28/11/14.
//  Copyright (c) 2014 Michi. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"


static NSDictionary<NSString *, NSString *> *sounds = nil;


#pragma mark - UIColor extension


@implementation UIColor  (Utils)

+ (UIColor *)colorNamed:(NSString *)colorName value:(CGFloat)value
{
	if (@available(iOS 11.0, *)) {
		return [UIColor colorNamed:colorName];
	} else {
		return [UIColor colorWithWhite:value alpha:1.0];
	}
}

@end


#pragma mark - Grid cell


@interface GridCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *title;

@end


@implementation GridCell

- (instancetype)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		self.layer.cornerRadius = 8;
		self.layer.borderWidth = 0.5;
		self.layer.borderColor = [UIColor colorWithWhite:0.65 alpha:0.4].CGColor;
		self.clipsToBounds = YES;
		CGFloat margin = 6;
		CGRect frame = CGRectInset(self.contentView.bounds, 2*margin, 2*margin);
		_title = [[UILabel alloc] initWithFrame:frame];
		_title.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_title.font = [UIFont systemFontOfSize:15];
		_title.textColor = [UIColor colorNamed:@"cellText" value:0.374];
		_title.textAlignment = NSTextAlignmentCenter;
		_title.numberOfLines = 0;
		[self.contentView addSubview:_title];
		self.contentView.backgroundColor = [UIColor colorNamed:@"cell" value:0.913];
	}

	return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
	CGFloat alpha = (highlighted) ? 0.5:1;
	CGFloat scale = (highlighted) ? 0.925:1;
	NSTimeInterval duration = (highlighted) ? .3:.5;

	[UIView animateWithDuration:duration delay:0
	options:UIViewAnimationOptionAllowUserInteraction animations:^{
		self.transform = CGAffineTransformMakeScale(scale, scale);
		self.alpha = alpha;
	} completion:nil];
}

@end


#pragma mark - View controller


@interface ViewController () <UICollectionViewDelegate,
                              UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) AVQueuePlayer *player;
@property (atomic) CGFloat direction;

@end


@implementation ViewController


#pragma mark View life cycle


- (void)viewDidLoad
{
	static dispatch_once_t once;
	dispatch_once(&once, ^{

		sounds = @{
			@"Abys mohl toto!": @"abych_mohl_toto",
			@"Ani očko nenasadíš!": @"ani_ocko_nenasadis",
			@"Ani za kokot vole!": @"ani_za_kokot_vole",
			@"Banální věc!": @"banalni_vec",
			@"Do piče!": @"do_pice",
			@"Hajzli jedni!": @"hajzli_jedni",
			@"Hoši, toto je neuvěřitelné!": @"hosi_to_je_neuveritelne",
			@"Jedinou pičovinku!": @"jedinou_picovinku",
			@"Jedu do piči!": @"jedu_do_pici_stadyma",
			@"Já se z toho musím pojebat!": @"ja_se_z_toho_musim_pojebat",
			@"Já to mrdám!": @"ja_to_mrdam",
			@"Já to nejdu dělat!": @"ja_to_nejdu_delat",
			@"Kurva už!": @"kurva_uz",
			@"KURVA!": @"kurva",
			@"Ne, nenasadíš ho!": @"ne_nenasadis_ho",
			@"Nebudu to dělat!": @"nebudu_to_delat",
			@"Největší blbec na zeměkouli!": @"nejvetsi_blbec_na_zemekouli",
			@"Nenasadím!": @"nenasadim",
			@"Nevím jak!": @"nevim_jak",
			@"Neřešitelný problém hoši!": @"neresitelny_problem_hosi",
			@"Okamžitě zabít ty kurvy!": @"okamzite_zabit_ty_kurvy",
			@"Past vedle pasti!": @"past_vedle_pasti_pico",
			@"Počkej kámo!": @"pockej_kamo",
			@"Tady musíš všechno rozdělat!": @"tady_musis_vsechno_rozdelat",
			@"To je nemožné!": @"to_je_pico_nemozne",
			@"To není možné!": @"kurva_do_pice_to_neni_mozne",
			@"To není normální": @"to_neni_normalni_kurva",
			@"To sou nervy ty pičo!": @"to_sou_nervy_ty_pico",
			@"Tuto piču potrebuju utáhnout!": @"tuto_picu_potrebuju_utahnout",
			@"Zasrané, zamrdané!": @"zasrane_zamrdane",
		};

	});

	[super viewDidLoad];

	_player = [AVQueuePlayer new];
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

	self.title = @"I Love My Job";
	self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title"]];

	self.view.backgroundColor = [UIColor colorNamed:@"background" value:0.988];
	self.navigationController.navigationBar.barTintColor = [UIColor colorNamed:@"navbar" value:0.92];

	_layout = [UICollectionViewFlowLayout new];
	[self updateLayout];

	_collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:_layout];
	_collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_collectionView.backgroundColor = [UIColor clearColor];
	[_collectionView registerClass:[GridCell class] forCellWithReuseIdentifier:@"Cell"];
	_collectionView.delegate = self;
	_collectionView.dataSource = self;
	[self.view addSubview:_collectionView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[_collectionView reloadData];
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	[self updateLayout];
}

- (void)updateLayout
{
	CGFloat width = CGRectGetWidth(_collectionView.bounds);
	CGFloat itemsPerLine = (width > 900) ? 6 : (width > 512) ? 5 : 3;
	width -= 2*8 + (itemsPerLine-1) * 8;
	width = CGFloor(width / itemsPerLine);

	_layout.itemSize = CGSizeMake(width, width);
	_layout.minimumInteritemSpacing = 8;
	_layout.minimumLineSpacing = 8;
	_layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
	_layout.headerReferenceSize = CGSizeZero;

	[_layout invalidateLayout];
}


#pragma mark Collection view delegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	static CGFloat lastOffset = 0;
	if (scrollView.contentOffset.y > lastOffset) _direction = 1;
	else if (scrollView.contentOffset.y < lastOffset) _direction = -1;
	else _direction = 0;
	lastOffset = scrollView.contentOffset.y;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return sounds.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	GridCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	cell.title.text = sounds.allKeys[indexPath.row];
	CGFloat trans = (_direction >= 0) ? 16:-42;
	cell.transform = CGAffineTransformMakeTranslation(16*(indexPath.row%3-1), trans);
	NSTimeInterval delay = 0;
	[UIView animateWithDuration:.4 delay:delay options:0 animations:^{
		cell.transform = CGAffineTransformMakeTranslation(0, 0);
	} completion:nil];
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	[self playSoundAtIndex:indexPath.row];
}


#pragma mark Actions


- (void)playSoundAtIndex:(NSInteger)index
{
	if (_player) [_player pause];

	NSString *key = sounds.allKeys[index];
	NSString *resourceName = sounds[key];
	NSURL *soundURL = [[NSBundle mainBundle] URLForResource:resourceName withExtension:@".m4a"];
	NSAssert(soundURL, @"URL is invalid");

	[_player removeAllItems];
	[_player insertItem:[AVPlayerItem playerItemWithURL:soundURL] afterItem:nil];
	[_player play];
}

@end


#pragma mark - Overriden UIFont class


@implementation UIFont (Utils)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (UIFont *)systemFontOfSize:(CGFloat)size
{
	return [UIFont fontWithName:@"Avenir-Medium" size:size];
}

+ (UIFont *)lightSystemFontOfSize:(CGFloat)size
{
	return [UIFont fontWithName:@"Avenir-Light" size:size];
}

+ (UIFont *)boldSystemFontOfSize:(CGFloat)size
{
	return [UIFont fontWithName:@"Avenir-Heavy" size:size];
}

+ (UIFont *)preferredFontForTextStyle:(NSString *)style
{
	if ([style isEqualToString:UIFontTextStyleBody])
		return [UIFont systemFontOfSize:17];
	if ([style isEqualToString:UIFontTextStyleHeadline])
		return [UIFont boldSystemFontOfSize:17];
	if ([style isEqualToString:UIFontTextStyleSubheadline])
		return [UIFont systemFontOfSize:15];
	if ([style isEqualToString:UIFontTextStyleFootnote])
		return [UIFont systemFontOfSize:13];
	if ([style isEqualToString:UIFontTextStyleCaption1])
		return [UIFont systemFontOfSize:12];
	if ([style isEqualToString:UIFontTextStyleCaption2])
		return [UIFont systemFontOfSize:11];
	return [UIFont systemFontOfSize:17];
}

- (UIFont *)fontAdjustedByPoints:(CGFloat)points
{
	return [self fontWithSize:self.pointSize+points];
}

#pragma clang diagnostic pop

@end
