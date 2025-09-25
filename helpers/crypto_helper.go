package helpers

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"
)

// GenerateUUID 生成一个简单的UUID用作加密密钥
func GenerateUUID() string {
	b := make([]byte, 16)
	rand.Read(b)
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}

// uuidToKey 将UUID转换为32字节的AES密钥
func uuidToKey(uuid string) []byte {
	// 移除UUID中的连字符
	cleanUUID := strings.ReplaceAll(uuid, "-", "")
	// 使用SHA256将UUID哈希为32字节密钥
	hash := sha256.Sum256([]byte(cleanUUID))
	return hash[:]
}

// DecryptResponseBody 使用UUID解密响应数据
func DecryptResponseBody(encryptedData []byte, uuid string) ([]byte, error) {
	// 如果UUID为空，说明不需要解密，直接返回原数据
	if uuid == "" {
		return encryptedData, nil
	}

	// 尝试Base64解码，如果失败说明数据可能没有加密
	ciphertext, err := base64.StdEncoding.DecodeString(string(encryptedData))
	if err != nil {
		// Base64解码失败，可能是未加密的数据（如JSON），直接返回
		return encryptedData, nil
	}

	// 生成AES密钥
	key := uuidToKey(uuid)

	// 创建AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, fmt.Errorf("create cipher failed: %v", err)
	}

	// 创建GCM
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, fmt.Errorf("create gcm failed: %v", err)
	}

	// 检查密文长度
	nonceSize := gcm.NonceSize()
	if len(ciphertext) < nonceSize {
		// 数据太短，不是有效的加密数据，返回原数据
		return encryptedData, nil
	}

	// 分离nonce和密文
	nonce, ciphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]

	// 解密
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		// 解密失败，可能是未加密的数据，返回原数据
		return encryptedData, nil
	}

	return plaintext, nil
}

// 可选：解密并反序列化为目标结构体
func DecryptAndUnmarshal(data []byte, v interface{}, uuid string) error {
	decrypted, err := DecryptResponseBody(data, uuid)
	if err != nil {
		return err
	}
	return json.Unmarshal(decrypted, v)
}
