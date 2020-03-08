package main

import (
	"fmt"
	"log"
	"net/http"
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

	errCh := make(chan error)

	go func() {
		errCh <- runGomibot()
	}()

	go func() {
		errCh <- runHTTPServer()
	}()

	return <-errCh
}

func runGomibot() error {
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
	return "../calendar"
}

func runHTTPServer() error {
	port := os.Getenv("PORT")
	http.HandleFunc("/", HTTPhandler)
	return http.ListenAndServe(":"+port, nil)
}

func HTTPhandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "(｀･ω･´)")
}
