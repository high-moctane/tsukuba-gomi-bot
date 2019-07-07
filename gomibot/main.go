package main

import (
	"log"
	"os"

	"github.com/dghubble/go-twitter/twitter"
	"github.com/dghubble/oauth1"
	"github.com/joho/godotenv"
)

func main() {
	if err := Run(); err != nil {
		log.Fatal(err)
	}
}

func Run() error {
	// .env の読み込み
	if err := godotenv.Load(); err != nil {
		return err
	}

	// カレンダーの作成
	cal, err := NewCalendar(CalDir())
	if err != nil {
		return err
	}

	// Twitter Client の作成
	config := oauth1.NewConfig(os.Getenv("CONSUMER_KEY"), os.Getenv("CONSUMER_SECRET"))
	token := oauth1.NewToken(os.Getenv("ACCESS_TOKEN"), os.Getenv("ACCESS_SECRET"))
	httpClient := config.Client(oauth1.NoContext, token)
	client := twitter.NewClient(httpClient)

	RegularTweetServer(client, cal)
	return nil
}

// TODO: この雑な実装をそのうちどうにかする
func CalDir() string {
	return os.Args[1]
}
