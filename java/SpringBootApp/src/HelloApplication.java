
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ImportResource;

/**
 * SpringBoot application main class. It uses JdbcTemplate class which
 * internally uses UCP for connection check-outs and check-ins.
 *
 */
// Specify the Spring XML config file name
@ImportResource({ "classpath*:HelloAppConfig.xml" })
public class HelloApplication {

	public static void main(String[] args) {
		SpringApplication.run(HelloApplication.class, args);
	}

	@Bean
	public CommandLineRunner commandLineRunner(ApplicationContext ctx) {
		return args -> {
			final EmpJDBCTemplate empJDBCTemplate = (EmpJDBCTemplate) ctx.getBean("EmpJDBCTemplate");
			System.out.println("Listing employee records : ");
			empJDBCTemplate.displayEmpList();
		};
	}

}
