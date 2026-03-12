extends AcceptDialog

signal password_entered(password: String)

func _on_confirmed():
	password_entered.emit($PasswordEdit.text)
	queue_free()
