package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"regexp"

	"github.com/howeyc/gopass"
	"golang.org/x/crypto/ssh"
)

// Settings is used for app settings
type Settings struct {
	Addr      string   `json:"addr"`
	Interface string   `json:"interface"`
	Hosts     []string `json:"hosts"`
}

func main() {
	defer func() {
		if err := recover(); err != nil {
			log.Println("panic occurred:", err)
		}
		fmt.Println("Press enter key to exit...")
		fmt.Scanln()
	}()

	content, _ := ioutil.ReadFile("./settings.json")

	var settings Settings

	json.Unmarshal(content, &settings)

	fmt.Print("Enter username: ")
	var username string
	fmt.Scanln(&username)

	fmt.Print("Enter password: ")
	password, _ := gopass.GetPasswd()

	config := &ssh.ClientConfig{
		User: username,
		Auth: []ssh.AuthMethod{ssh.Password(string(password))},
	}

	config.HostKeyCallback = ssh.InsecureIgnoreHostKey()

	conn, err := ssh.Dial("tcp", settings.Addr, config)
	if err != nil {
		panic("Failed to dial: " + err.Error())
	}
	defer conn.Close()

	runningConfig := executeCmd("show running-config", conn)

	r := regexp.MustCompile(fmt.Sprintf(`ip route (\d+.\d+.\d+.\d+) %s`, settings.Interface))

	matches := r.FindAllStringSubmatch(runningConfig, -1)

	for _, match := range matches {
		ip := match[1]
		fmt.Print(executeCmd(fmt.Sprintf("no ip route %s %s", ip, settings.Interface), conn))
	}

	fmt.Println()

	for _, host := range settings.Hosts {
		ips, _ := net.DefaultResolver.LookupIP(context.Background(), "ip4", host)

		for _, ip := range ips {
			fmt.Printf("%s - %s", host, executeCmd(fmt.Sprintf("ip route %s %s !%s", ip, settings.Interface, host), conn))
		}
	}

	fmt.Println()
}

func executeCmd(cmd string, conn *ssh.Client) string {
	session, err := conn.NewSession()
	if err != nil {
		log.Fatal("Failed to create session: ", err)
	}
	defer session.Close()

	var b bytes.Buffer
	session.Stdout = &b
	if err := session.Run(cmd); err != nil {
		log.Fatal("Failed to run: " + err.Error())
	}

	return b.String()
}
