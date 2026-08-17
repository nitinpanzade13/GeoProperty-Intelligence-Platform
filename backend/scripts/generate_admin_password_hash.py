import getpass

from app.core.security import hash_password


def main():
    password = getpass.getpass("Enter admin password: ")

    if not password:
        raise ValueError("Password cannot be empty.")

    password_hash = hash_password(password)

    print("\nPassword hash:")
    print(password_hash)


if __name__ == "__main__":
    main()