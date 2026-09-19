extends SceneTree
## Headless CLI runner for DataValidator.


func _init() -> void:
	print("==> Executando Validação de Dados...")
	var results: Dictionary = DataValidator.validate_all()
	print(
		(
			"Validação concluída: %d arquivos verificados. %d erros, %d avisos."
			% [results["validated_count"], results["errors"].size(), results["warnings"].size()]
		)
	)

	if not results["warnings"].is_empty():
		for w in results["warnings"]:
			print("  [AVISO] %s" % w)

	if results["success"]:
		print("==> SUCESSO: Todos os dados do projeto estão consistentes e válidos!")
		quit(0)
	else:
		for err in results["errors"]:
			printerr("  [ERRO] %s" % err)
		printerr("==> FALHA: Erros encontrados nos dados do projeto.")
		quit(1)
