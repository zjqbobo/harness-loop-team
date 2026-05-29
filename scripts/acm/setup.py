from setuptools import setup, find_packages

setup(
    name="acm",
    version="0.1.0",
    packages=find_packages(),
    install_requires=["requests>=2.28.0"],
    extras_require={"dev": ["pytest>=7.0", "pytest-cov>=4.0"]},
    entry_points={
        "console_scripts": [
            "acm-agent=acm.__main__:main",
            "acm-blame=acm.collector.blame:main",
        ],
    },
    python_requires=">=3.8",
)
