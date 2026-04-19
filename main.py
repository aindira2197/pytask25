class Validator:
    def __init__(self, func):
        self.func = func

    def __call__(self, *args, **kwargs):
        for arg in args:
            if not isinstance(arg, (int, float, str, bool)):
                raise TypeError("Invalid argument type")
        result = self.func(*args, **kwargs)
        return result

def validate_type(expected_type):
    def decorator(func):
        def wrapper(*args, **kwargs):
            for arg in args:
                if not isinstance(arg, expected_type):
                    raise TypeError("Invalid argument type")
            result = func(*args, **kwargs)
            return result
        return wrapper
    return decorator

@Validator
def add(a, b):
    return a + b

@validate_type(int)
def multiply(a, b):
    return a * b

@validate_type(str)
def greet(name):
    return f"Hello, {name}!"

class User:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    @Validator
    def get_user_info(self):
        return f"Name: {self.name}, Age: {self.age}"

    @validate_type(int)
    def set_age(self, age):
        self.age = age

    @validate_type(str)
    def set_name(self, name):
        self.name = name

def main():
    user = User("John", 30)
    print(user.get_user_info())
    user.set_age(31)
    print(user.get_user_info())
    user.set_name("Jane")
    print(user.get_user_info())
    print(add(2, 3))
    print(multiply(4, 5))
    print(greet("Alice"))

if __name__ == "__main__":
    main()