package gomibot

import "fmt"
import "regexp"

// Garbage is a type of garbage
type Garbage int

const (
	// NoCollecting means 収集なし
	NoCollecting = iota

	// BurnableGarbage means 燃やせるごみ
	BurnableGarbage

	// UsedPaperAndClothes means 古紙・古布
	UsedPaperAndClothes

	// GlassBottlesAndSplayCans means びん・スプレー容器
	GlassBottlesAndSplayCans

	// PlasticBottles means ペットボトル
	PlasticBottles

	// OversizedGarbage means 粗大ごみ
	OversizedGarbage

	// Cans means 缶
	Cans

	// NonBurnableGarbage means 燃やせないごみ
	NonBurnableGarbage
)

// regexps which is used for judging input strings
var regexpBurnableGarbage = regexp.MustCompile(`(燃|も|萌)(える|や(す|せる))`)
var regexpUsedPaperAndClothes = regexp.MustCompile(`紙|こし|かみ|布|ぬの|こふ`)
var regexpGlassBottlesAndSplayCans = regexp.MustCompile(`びん|ビン|瓶|スプレー|すぷれー`)
var regexpPlasticBottles = regexp.MustCompile(`ペット|ぺっと`)
var regexpOversizedGarbage = regexp.MustCompile(`粗大|そだい`)
var regexpCans = regexp.MustCompile(`缶|かん|カン`)
var regexpNonBurnableGarbage = regexp.MustCompile(`(燃|も|萌)(えない|や(さ|せ)ない)`)

// IsBurnableGarbage returns if s means BurnableGarbage
func IsBurnableGarbage(s string) bool {
	return regexpBurnableGarbage.MatchString(s)
}

// IsUsedPaperAndClothes returns if s means UsedPaperAndClothes
func IsUsedPaperAndClothes(s string) bool {
	return regexpUsedPaperAndClothes.MatchString(s)
}

// IsGlassBottlesAndSplayCans returns if s means GlassBottlesAndSplayCans
func IsGlassBottlesAndSplayCans(s string) bool {
	return regexpGlassBottlesAndSplayCans.MatchString(s)
}

// IsPlasticBottles returns if s means PlasticBottles
func IsPlasticBottles(s string) bool {
	return regexpPlasticBottles.MatchString(s)
}

// IsOversizedGarbage returns if s means OversizedGarbage
func IsOversizedGarbage(s string) bool {
	return regexpOversizedGarbage.MatchString(s)
}

// IsCans returns if s means Cans
func IsCans(s string) bool {
	return !regexpGlassBottlesAndSplayCans.MatchString(s) &&
		regexpCans.MatchString(s)
}

// IsNonBurnableGarbage returns if s means NonBurnableGarbage
func IsNonBurnableGarbage(s string) bool {
	return regexpNonBurnableGarbage.MatchString(s)
}

func (g Garbage) String() string {
	switch g {
	case NoCollecting:
		return "収集なし"
	case BurnableGarbage:
		return "燃やせるごみ"
	case UsedPaperAndClothes:
		return "古紙・古布"
	case GlassBottlesAndSplayCans:
		return "びん・スプレー容器"
	case PlasticBottles:
		return "ペットボトル"
	case OversizedGarbage:
		return "粗大ごみ"
	case Cans:
		return "かん"
	case NonBurnableGarbage:
		return "燃やせないごみ"
	}
	panic(fmt.Sprintf("%d is not a member of Garbage", g))
}
