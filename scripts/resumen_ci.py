"""Publica los resultados reales del TRX en el resumen de GitHub Actions."""

import os
from pathlib import Path
import xml.etree.ElementTree as ET

trx_path = Path("TestResults/resultados.trx")
summary_path = Path(os.environ["GITHUB_STEP_SUMMARY"])
namespace = {"t": "http://microsoft.com/schemas/VisualStudio/TeamTest/2010"}

with summary_path.open("a", encoding="utf-8") as report:
    report.write("# Resultados del examen final\n\n")
    report.write("Revision: " + os.environ["GITHUB_SHA"] + "\n\n")
    if not trx_path.exists():
        report.write("No se genero el TRX. Revisar la compilacion y las pruebas.\n")
    else:
        root = ET.parse(trx_path).getroot()
        counters = root.find("t:ResultSummary/t:Counters", namespace).attrib
        report.write(
            "**Total: {total} | Correctas: {passed} | Fallidas: {failed} | "
            "Omitidas: {notExecuted}**\n\n".format(**counters)
        )
        report.write(
            "Compilacion Release con advertencias tratadas como errores. "
            "SQLite real; API con HttpClient y WebApplicationFactory.\n\n"
        )
        report.write("| Prueba | Resultado |\n| --- | --- |\n")
        tests = root.findall("t:Results/t:UnitTestResult", namespace)
        for test in sorted(tests, key=lambda node: node.get("testName")):
            name = test.get("testName").removeprefix("ClienteApp.Tests.")
            report.write("| " + name + " | " + test.get("outcome") + " |\n")
