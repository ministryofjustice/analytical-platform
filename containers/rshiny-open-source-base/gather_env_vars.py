import os


R_ENV_FILE_NAME = "/srv/shiny-server/.Renviron"
R_ENV_FILE_NAME1 = "/home/shiny/.Renviron"


def gather_env_vars_to_renv_file():
    with open(R_ENV_FILE_NAME, "a") as file_hanelder:
        for name, value in os.environ.items():
            file_hanelder.write(f'{name}="{value}"')
            file_hanelder.write("\n")

    with open(R_ENV_FILE_NAME1, "a") as file_hanelder:
        for name, value in os.environ.items():
            # file_hanelder.write(f'export {name}="{value}"')
            file_hanelder.write(f'{name}="{value}"')
            file_hanelder.write("\n")


if __name__ == '__main__':
    gather_env_vars_to_renv_file()
