import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/student.dart';

class SelectedStudentCubit extends Cubit<Student?> {
  SelectedStudentCubit() : super(null);

  void select(Student student) => emit(student);
  
  void clear() => emit(null);
}
