.PHONY: gen
gen:
	mkdir -p ./lib/generated/grpc_pb
	protoc --proto_path=../VooSu-server/api/proto/app \
		--dart_out=grpc:./lib/generated/grpc_pb \
		../VooSu-server/api/proto/app/*.proto

	dart run build_runner build --delete-conflicting-outputs
