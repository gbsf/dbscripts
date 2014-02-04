load ../lib/common

@test "commands display usage message by default" {
	for cmd in db-move db-remove db-add testing2x; do
		echo Testing $cmd
		run $cmd
		(( $status == 1 ))
		[[ $output == *'usage: '* ]]
	done
}
