//go:build !cgo

package main

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"strconv"
	"sync"
)

var (
	conn   net.Conn
	connMu sync.Mutex
)

func (result ActionResult) send() {
	data, err := result.Json()
	if err != nil {
		return
	}
	send(data)
}

func sendMessage(message Message) {
	result := ActionResult{
		Method: messageMethod,
		Data:   message,
	}
	result.send()
}

func writeFrame(w io.Writer, data []byte) error {
	frame := make([]byte, 4+len(data))
	binary.LittleEndian.PutUint32(frame, uint32(len(data)))
	copy(frame[4:], data)
	_, err := w.Write(frame)
	return err
}

// maxFrameLength bounds a single frame read from the app. The largest
// legitimate payloads are full config texts carried inline by actions such
// as validateConfig and decryptAgeConfig; real-world profiles sit far
// below this bound (the 64MiB decompressed-profile cap applies to the
// on-disk import path, whose bytes never traverse a frame). 32MiB keeps
// generous headroom while capping the allocation a broken or hostile peer
// can force through readFrame (AM-07/T283).
const maxFrameLength = 32 * 1024 * 1024

func readFrame(r io.Reader) ([]byte, error) {
	lenBuf := make([]byte, 4)
	if _, err := io.ReadFull(r, lenBuf); err != nil {
		return nil, err
	}
	length := binary.LittleEndian.Uint32(lenBuf)

	if length > maxFrameLength {
		return nil, fmt.Errorf("frame too large: %d", length)
	}

	data := make([]byte, length)
	if _, err := io.ReadFull(r, data); err != nil {
		return nil, err
	}
	return data, nil
}

func send(data []byte) {
	if conn == nil {
		return
	}
	connMu.Lock()
	defer connMu.Unlock()
	if err := writeFrame(conn, data); err != nil {
		logError("send error: %v", err)
	}
}

func startServer(arg string) {
	_, err := strconv.Atoi(arg)

	if err != nil {
		conn, err = net.Dial("unix", arg)
	} else {
		conn, err = net.Dial("tcp", fmt.Sprintf("127.0.0.1:%s", arg))
	}
	if err != nil {
		panic(err.Error())
	}

	defer func() {
		_ = conn.Close()
	}()

	for {
		data, err := readFrame(conn)
		if err != nil {
			if err != io.EOF {
				logError("read error: %v", err)
			}
			return
		}

		var action = &Action{}
		if err = json.Unmarshal(data, action); err != nil {
			logError("unmarshal error: %v", err)
			continue
		}

		result := ActionResult{
			Id:     action.Id,
			Method: action.Method,
		}

		go handleAction(action, result)
	}
}

func nextHandle(action *Action, result ActionResult) bool {
	return false
}

func logError(format string, v ...interface{}) {
	log.Printf(format, v...)
}
